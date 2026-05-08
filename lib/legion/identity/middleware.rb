# frozen_string_literal: true

module Legion
  module Identity
    class Middleware
      SKIP_PATHS     = %w[/api/health /api/ready /api/openapi.json /metrics].freeze
      LOOPBACK_BINDS = %w[127.0.0.1 ::1 localhost].freeze

      def initialize(app, require_auth: false)
        @app          = app
        @require_auth = require_auth
      end

      def call(env)
        return @app.call(env) if skip_path?(env['PATH_INFO'])

        # Bridge from existing auth middleware
        auth_claims  = env['legion.auth']
        auth_method  = env['legion.auth_method']

        request = if auth_claims
                    build_request(auth_claims, auth_method)
                  elsif @require_auth
                    # Auth middleware already handled 401 for protected paths;
                    # this is a safety net for any path that slipped through.
                    nil
                  else
                    # No auth required (loopback bind, lite mode, etc.).
                    # Set a system-level principal so audit trails always have an identity.
                    system_principal
                  end

        env['legion.principal'] = request

        # Bridge to RBAC principal if legion-rbac is loaded.
        # This is a data bridge — set regardless of enforce/audit mode so
        # the RBAC middleware always has a typed principal to evaluate.
        # Guard: require Legion::Rbac.enabled? to confirm the real gem is loaded
        # (not a minimal test stub), and rescue construction errors defensively.
        if request && defined?(Legion::Rbac::Principal) &&
           defined?(Legion::Rbac) && Legion::Rbac.respond_to?(:enabled?) &&
           Legion::Rbac.enabled?
          begin
            env['legion.rbac_principal'] = Legion::Rbac::Principal.new(
              id:    request.principal_id,
              type:  request.kind == :service ? :worker : request.kind,
              roles: request.roles,
              team:  request.metadata&.dig(:team)
            )
          rescue StandardError
            # Best-effort bridge: leave legion.rbac_principal unset on construction errors.
          end
        end

        @app.call(env)
      end

      # Returns whether the API should require authentication.
      # Skips auth for lite mode and loopback binds (local dev / CI).
      def self.require_auth?(bind:, mode:)
        return false if mode == :lite
        return false if LOOPBACK_BINDS.include?(bind)

        true
      end

      private

      def skip_path?(path)
        SKIP_PATHS.any? { |p| path.start_with?(p) }
      end

      def build_request(claims, method)
        # Use worker_id as principal_id when present — worker tokens encode both
        # worker_id and sub=owner_msid, and we want the worker's identity, not the owner's.
        principal_id = claims[:worker_id] || claims[:sub] || claims[:owner_msid]

        # For worker tokens (scope: 'worker' or worker_id present), derive canonical_name
        # from the worker's own identity. Production worker JWTs omit :name and carry
        # sub=owner_msid, so falling back to claims[:sub] would inherit the owner's identity.
        worker_token = claims[:scope] == 'worker' || claims[:worker_id]
        display_name = claims[:name] || (worker_token ? principal_id : claims[:sub])

        # Separate group OIDs/names from Entra app roles — they are NOT equivalent.
        # claims[:groups] = group OIDs/names (for GroupRoleMapper)
        # claims[:roles]  = Entra app roles (pre-assigned at token-exchange time)
        groups = Array(claims[:groups])
        roles  = Array(claims[:roles])

        # Enrich with group-derived RBAC roles when legion-rbac is loaded (including audit mode).
        resolved_roles = if defined?(Legion::Rbac::GroupRoleMapper) &&
                            Legion::Rbac.respond_to?(:enabled?) &&
                            Legion::Rbac.enabled?
                           group_roles = Legion::Rbac::GroupRoleMapper.resolve_roles(groups: groups)
                           (roles + group_roles).uniq
                         else
                           roles
                         end

        Identity::Request.from_auth_context({
                                              sub:            principal_id,
                                              name:           display_name,
                                              kind:           determine_kind(claims, method),
                                              groups:         groups,
                                              resolved_roles: resolved_roles,
                                              source:         method&.to_sym
                                            })
      end

      def determine_kind(claims, method)
        return :service if claims[:scope] == 'worker' || claims[:worker_id]
        return :human   if method == 'kerberos' || claims[:scope] == 'human'

        :human
      end

      def system_principal
        attrs = system_identity_attributes

        if @system_principal&.canonical_name != attrs[:canonical_name] ||
           @system_principal&.kind != attrs[:kind] ||
           @system_principal&.source != Identity::Request::SOURCE_NORMALIZATION.fetch(attrs[:source], attrs[:source])
          @system_principal = Identity::Request.new(
            principal_id:   "system:#{attrs[:canonical_name]}",
            canonical_name: attrs[:canonical_name],
            kind:           attrs[:kind],
            groups:         [],
            source:         attrs[:source]
          )
        end
        @system_principal
      end

      def system_identity_attributes
        process = defined?(Legion::Identity::Process) ? Legion::Identity::Process : nil
        canonical = process_value(process, :canonical_name)
        canonical = 'system' if canonical.nil? || canonical.to_s.empty?

        {
          canonical_name: canonical.to_s,
          kind:           process_value(process, :kind) || :service,
          source:         process_value(process, :source) || :local
        }
      end

      def process_value(process, method_name)
        return nil unless process.respond_to?(method_name)

        process.public_send(method_name)
      rescue StandardError
        nil
      end
    end
  end
end
