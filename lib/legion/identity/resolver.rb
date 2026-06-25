# frozen_string_literal: true

require 'securerandom'
require 'fileutils'
require 'concurrent/array'
require 'concurrent/atomic/atomic_reference'
require 'concurrent/atomic/atomic_boolean'
require 'concurrent/promises'

module Legion
  module Identity
    module Resolver
      TIMEOUT_SECONDS = 5

      class << self
        include Legion::Logging::Helper

        def register(provider)
          return if @providers.any? { |p| p.provider_name == provider.provider_name }

          log.debug("register: #{provider.provider_name} type=#{provider.provider_type} trust=#{provider.trust_level}")
          @providers << provider
        end

        def resolve!(timeout: TIMEOUT_SECONDS)
          log.debug("resolve!: starting with #{@providers.size} providers, timeout=#{timeout}s")
          drain_pending_registrations

          auth_providers, profile_providers, fallback_providers = partition_providers
          log.debug("resolve!: partitioned auth=#{auth_providers.map(&:provider_name)} " \
                    "profile=#{profile_providers.map(&:provider_name)} " \
                    "fallback=#{fallback_providers.map(&:provider_name)}")

          winning_provider, winning_result, provider_results = resolve_auth(auth_providers, timeout: timeout)

          if winning_provider.nil?
            log.debug('resolve!: no auth winner, trying cached identity')
            winning_provider, winning_result, cached_results = resolve_cached_identity
            provider_results.merge!(cached_results) if cached_results
          end

          if winning_provider.nil?
            log.debug('resolve!: no auth winner, trying fallback providers')
            winning_provider, winning_result, fallback_results = resolve_auth(fallback_providers, timeout: timeout)
            provider_results.merge!(fallback_results) if fallback_results
          end

          unless winning_provider
            log.debug('resolve!: no provider resolved, identity unresolved')
            @resolved.make_false
            @composite.set(nil)
            return nil
          end

          canonical = winning_result[:canonical_name]
          trust_level = winning_provider.trust_level
          source = winning_provider.provider_name
          log.debug("resolve!: winner=#{source} canonical=#{canonical} trust=#{trust_level}")

          profile_data = resolve_profiles(profile_providers, canonical, timeout: timeout)
          log.debug("resolve!: profiles resolved groups=#{profile_data[:groups].size} profile_keys=#{profile_data[:profile].keys}")

          composite = assemble_composite(
            provider_results, profile_data,
            winning_result: winning_result,
            trust_level:    trust_level,
            source:         source
          )

          bind_and_persist(winning_provider, composite, trust_level)
          log.debug("resolve!: complete canonical=#{composite[:canonical_name]} providers=#{composite[:providers].keys}")
          composite
        end

        def upgrade!(provider, result)
          current = @composite.get
          return unless current

          log.debug("upgrade!: provider=#{provider.provider_name} trust=#{provider.trust_level} current_canonical=#{current[:canonical_name]}")

          new_trust = provider.trust_level
          new_canonical = result[:canonical_name] || current[:canonical_name]
          canonical_changed = new_canonical != current[:canonical_name]

          # Only promote the composite trust level when the new provider's trust
          # is strictly higher (lower rank index) than the current level.
          # This prevents an accidental downgrade if upgrade! is called with a
          # lower-trust provider such as one with :unverified trust.
          current_trust = current[:trust]
          effective_trust = if defined?(Legion::Identity::Trust) &&
                               Legion::Identity::Trust.respond_to?(:above?) &&
                               Legion::Identity::Trust.above?(new_trust, current_trust)
                              new_trust
                            else
                              current_trust
                            end

          new_aliases = current[:aliases].dup
          provider_identity = result[:provider_identity]
          if provider_identity
            existing = Array(new_aliases[provider.provider_name])
            new_aliases[provider.provider_name] = (existing + [provider_identity]).uniq
          end

          new_providers = current[:providers].dup
          new_providers[provider.provider_name] = {
            status:      :resolved,
            trust:       new_trust,
            resolved_at: Time.now
          }

          updated = current.merge(
            canonical_name: new_canonical,
            trust:          effective_trust,
            source:         provider.provider_name,
            aliases:        new_aliases,
            providers:      new_providers
          )

          handle_canonical_change(current[:canonical_name], new_canonical, updated) if canonical_changed

          @composite.set(updated)
          Legion::Identity::Process.bind!(provider, updated) if defined?(Legion::Identity::Process)

          if defined?(Legion::Settings) && Legion::Settings.respond_to?(:loader) && Legion::Settings.loader.respond_to?(:settings)
            Legion::Settings.loader.settings[:client] ||= {}
            Legion::Settings.loader.settings[:client][:name] = Legion::Identity::Process.queue_prefix
          end

          persist_identity_json(new_canonical, updated[:kind]) unless new_trust == :unverified

          log.debug("upgrade!: complete canonical=#{new_canonical} trust=#{effective_trust} canonical_changed=#{canonical_changed}")
          updated
        end

        def resolved?
          @resolved.true?
        end

        def composite
          @composite.get
        end

        def providers
          @providers.dup
        end

        attr_reader :session_id

        def reset!
          @composite  = Concurrent::AtomicReference.new(nil)
          @resolved   = Concurrent::AtomicBoolean.new(false)
          @session_id = SecureRandom.uuid
        end

        def reset_all!
          reset!
          @providers = Concurrent::Array.new
        end

        private

        def drain_pending_registrations
          return unless defined?(Legion::Identity) && Legion::Identity.respond_to?(:pending_registrations)

          pending = Legion::Identity.pending_registrations
          return if pending.nil? || pending.empty?

          log.debug("drain_pending_registrations: draining #{pending.size} pending providers")
          drained = []
          drained << pending.shift until pending.empty?
          drained.each { |p| register(p) }
        end

        def partition_providers
          auth     = []
          profile  = []
          fallback = []

          @providers.each do |p|
            case p.provider_type
            when :auth     then auth << p
            when :profile  then profile << p
            when :fallback then fallback << p
            end
          end

          auth.sort_by! { |p| [-p.priority, p.trust_weight] }
          fallback.sort_by! { |p| [-p.priority, p.trust_weight] }

          [auth, profile, fallback]
        end

        def resolve_auth(auth_providers, timeout:)
          return [nil, nil, {}] if auth_providers.empty?

          log.debug("resolve_auth: racing #{auth_providers.map(&:provider_name)} timeout=#{timeout}s")
          futures = auth_providers.map do |provider|
            Concurrent::Promises.future { provider.resolve }
          end

          deadline = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) + timeout
          provider_results = {}
          auth_providers.zip(futures).each do |provider, future|
            result = nil
            remaining = deadline - ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
            future.wait(remaining.positive? ? remaining : 0)
            result = future.value(0) if future.resolved?
            status = auth_future_status(future, result)
            log.debug("resolve_auth: #{provider.provider_name} status=#{status}" \
                      "#{" canonical=#{result[:canonical_name]}" if status == :resolved}")

            provider_results[provider.provider_name] = {
              status:      status,
              trust:       (status == :resolved ? provider.trust_level : nil),
              resolved_at: (status == :resolved ? Time.now : nil),
              provider:    provider,
              result:      (status == :resolved ? result : nil)
            }
          end

          resolved_entries = provider_results.select { |_, v| v[:status] == :resolved }
          if resolved_entries.empty?
            log.debug('resolve_auth: no providers resolved')
            [nil, nil, provider_results]
          else
            winner_name = resolved_entries.min_by do |_, v|
              p = v[:provider]
              [-p.priority, p.trust_weight]
            end&.first

            log.debug("resolve_auth: winner=#{winner_name}")
            winner_info = provider_results[winner_name]
            [winner_info[:provider], winner_info[:result], provider_results]
          end
        end

        def resolve_cached_identity
          cached = read_cached_identity
          return [nil, nil, {}] unless cached

          provider = cached_identity_provider
          result = {
            canonical_name: cached[:canonical_name],
            kind:           cached[:kind] || :human,
            source:         :identity_json,
            persistent:     true
          }

          [
            provider,
            result,
            {
              provider.provider_name => {
                status:      :resolved,
                trust:       provider.trust_level,
                resolved_at: Time.now,
                provider:    provider,
                result:      result
              }
            }
          ]
        end

        def read_cached_identity
          path = File.expand_path('~/.legionio/settings/identity.json')
          return nil unless File.file?(path)

          data = if defined?(Legion::JSON)
                   Legion::JSON.load(File.read(path))
                 else
                   require 'json'
                   ::JSON.parse(File.read(path), symbolize_names: true)
                 end
          canonical = data[:canonical_name] || data['canonical_name']
          return nil if canonical.to_s.strip.empty?

          {
            canonical_name: canonical.to_s,
            kind:           (data[:kind] || data['kind'] || :human).to_sym
          }
        rescue StandardError => e
          log.warn("identity.json read failed: #{e.message}")
          nil
        end

        def cached_identity_provider
          @cached_identity_provider ||= Module.new do
            module_function

            def provider_name = :identity_cache
            def provider_type = :auth
            def priority = -100
            def trust_weight = 150
            def trust_level = :cached
          end
        end

        def auth_future_status(future, result)
          if future.rejected?
            :failed
          elsif !future.resolved?
            :timeout
          elsif result.is_a?(Hash) && result[:canonical_name]
            :resolved
          else
            :no_identity
          end
        end

        def resolve_profiles(profile_providers, canonical, timeout:)
          return { groups: [], profile: {}, provider_results: {} } if profile_providers.empty?

          futures = profile_providers.map do |provider|
            Concurrent::Promises.future { resolve_profile_provider(provider, canonical) }
          end

          deadline = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) + timeout
          groups = []
          profile = {}
          pr = {}

          profile_providers.zip(futures).each do |provider, future|
            remaining = deadline - ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
            future.wait(remaining.positive? ? remaining : 0)
            result = future.resolved? ? future.value(0) : nil

            if future.fulfilled? && result.is_a?(Hash)
              groups.concat(Array(result[:groups])) if result[:groups]
              profile.merge!(result[:profile]) if result[:profile].is_a?(Hash)
              pr[provider.provider_name] = { status: :resolved, trust: provider.trust_level, resolved_at: Time.now }
            else
              pr[provider.provider_name] = { status: (future.rejected? ? :failed : :timeout), trust: nil, resolved_at: nil }
            end
          end

          { groups: groups.uniq, profile: profile, provider_results: pr }
        end

        def resolve_profile_provider(provider, canonical)
          if provider.respond_to?(:resolve_all)
            provider.resolve_all(canonical_name: canonical)
          else
            provider.resolve(canonical_name: canonical)
          end
        end

        def assemble_composite(provider_results, profile_data, winning_result:, trust_level:, source:)
          aliases = build_aliases(provider_results)
          providers_map = build_providers_map(provider_results, profile_data)

          {
            id:             nil,
            canonical_name: winning_result[:canonical_name],
            kind:           winning_result[:kind] || :human,
            trust:          trust_level,
            source:         source,
            persistent:     true,
            aliases:        aliases,
            groups:         profile_data[:groups],
            profile:        profile_data[:profile],
            providers:      providers_map,
            metadata:       {}
          }
        end

        def build_aliases(provider_results)
          aliases = {}
          provider_results.each do |name, info|
            next unless info[:status] == :resolved && info[:result]

            pi = info[:result][:provider_identity]
            aliases[name] = [pi] if pi
          end
          aliases
        end

        def build_providers_map(provider_results, profile_data)
          providers_map = {}
          provider_results.each do |name, info|
            providers_map[name] = {
              status:      info[:status],
              trust:       info[:trust],
              resolved_at: info[:resolved_at]
            }
          end
          profile_data[:provider_results].each do |name, info|
            providers_map[name] = info
          end
          providers_map
        end

        def bind_and_persist(winning_provider, composite, trust_level)
          log.debug("bind_and_persist: binding provider=#{winning_provider.provider_name} trust=#{trust_level}")
          Legion::Identity::Process.bind!(winning_provider, composite) if defined?(Legion::Identity::Process)

          if defined?(Legion::Settings) && Legion::Settings.respond_to?(:loader) && Legion::Settings.loader.respond_to?(:settings)
            Legion::Settings.loader.settings[:client] ||= {}
            Legion::Settings.loader.settings[:client][:name] = Legion::Identity::Process.queue_prefix
            log.debug("bind_and_persist: client name set to #{Legion::Identity::Process.queue_prefix}")
          end

          persist_to_db(composite)
          persist_identity_json(composite[:canonical_name], composite[:kind]) unless trust_level == :unverified

          @composite.set(composite)
          @resolved.make_true
          log.debug('bind_and_persist: resolved=true')
        end

        def persist_to_db(composite)
          unless defined?(Legion::Data) && Legion::Data.respond_to?(:connected?) && Legion::Data.connected?
            log.debug('persist_to_db: skipped — Legion::Data not connected')
            return
          end

          log.debug("persist_to_db: persisting canonical=#{composite[:canonical_name]} providers=#{composite[:providers]&.keys}")
          now            = Time.now.utc
          provider_model = Legion::Data::Model::Identity::Provider
          audit_model    = Legion::Data::Model::Identity::AuditLog

          upsert_providers(composite, provider_model, now)
          principal = upsert_principal(composite, now)
          upsert_identities(composite, provider_model, principal, now)

          audit_model.create(
            principal_id:   principal.id,
            event_type:     'identity.resolved',
            provider_name:  composite[:source].to_s,
            trust_level:    composite[:trust]&.to_s,
            detail_payload: Legion::JSON.dump(
              {
                source:     composite[:source],
                trust:      composite[:trust],
                node_id:    composite[:node_id],
                session_id: @session_id
              }
            ),
            node_ref:       composite[:node_id],
            session_ref:    @session_id
          )
        rescue StandardError => e
          log.warn("DB persistence failed: #{e.message}")
        end

        def upsert_providers(composite, provider_model, now)
          composite[:providers]&.each_key do |name|
            existing = provider_model.where(name: name.to_s).first
            if existing
              existing.update(updated_at: now)
            else
              provider_model.create(
                name:          name.to_s,
                provider_type: 'authenticate',
                facing:        'both',
                source:        'resolver',
                enabled:       true
              )
            end
          end
        end

        def upsert_principal(composite, now)
          principal_model = Legion::Data::Model::Identity::Principal
          principal = principal_model.where(
            canonical_name: composite[:canonical_name],
            kind:           composite[:kind].to_s
          ).first

          if principal
            principal.update(last_seen_at: now, updated_at: now)
            principal
          else
            principal_model.create(
              canonical_name: composite[:canonical_name],
              kind:           composite[:kind].to_s,
              active:         true,
              last_seen_at:   now
            )
          end
        end

        def upsert_identities(composite, provider_model, principal, now)
          identity_model = Legion::Data::Model::Identity::Identity
          composite[:aliases]&.each do |provider_name, identities|
            provider_row = provider_model.where(name: provider_name.to_s).first
            next unless provider_row

            Array(identities).each do |ident|
              upsert_single_identity(identity_model, principal, provider_row, ident, now)
            end
          end
        end

        def upsert_single_identity(identity_model, principal, provider_row, ident, now)
          existing = identity_model.where(
            principal_id:          principal.id,
            provider_id:           provider_row.id,
            provider_identity_key: ident
          ).first

          if existing
            existing.update(last_authenticated_at: now, updated_at: now)
          else
            identity_model.create(
              principal_id:          principal.id,
              provider_id:           provider_row.id,
              provider_identity_key: ident,
              active:                true,
              last_authenticated_at: now
            )
          end
        end

        def persist_identity_json(canonical_name, kind)
          dir = File.expand_path('~/.legionio/settings')
          FileUtils.mkdir_p(dir)
          path = File.join(dir, 'identity.json')
          payload = { canonical_name: canonical_name, kind: kind }
          json = if defined?(Legion::JSON)
                   Legion::JSON.dump(payload)
                 else
                   require 'json'
                   ::JSON.generate(payload)
                 end
          File.write(path, json)
        rescue StandardError => e
          log.warn("identity.json write failed: #{e.message}")
        end

        def handle_canonical_change(old_canonical, new_canonical, _composite)
          if defined?(Legion::Settings) && Legion::Settings.respond_to?(:loader)
            settings = Legion::Settings.loader.settings
            settings[:client] ||= {}
            settings[:client][:name] = new_canonical
          end

          return unless defined?(Legion::Data) && Legion::Data.respond_to?(:connected?) && Legion::Data.connected?

          old_principal = Legion::Data::Model::Identity::Principal.where(canonical_name: old_canonical).first
          Legion::Data::Model::Identity::AuditLog.create(
            principal_id:   old_principal&.id,
            event_type:     'identity.canonical_changed',
            provider_name:  'resolver',
            detail_payload: Legion::JSON.dump({ old: old_canonical, new: new_canonical })
          )
        rescue StandardError => e
          log.warn("canonical change handling failed: #{e.message}")
        end
      end

      # Initialize atomics at module definition time
      @providers  = Concurrent::Array.new
      @composite  = Concurrent::AtomicReference.new(nil)
      @resolved   = Concurrent::AtomicBoolean.new(false)
      @session_id = SecureRandom.uuid
    end
  end
end
