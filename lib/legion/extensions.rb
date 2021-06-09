require 'legion/extensions/core'
require 'legion/runner'

module Legion
  module Extensions
    class << self
      def setup
        hook_extensions
      end

      def hook_extensions
        @timer_tasks = []
        @loop_tasks = []
        @once_tasks = []
        @poll_tasks = []
        @subscription_tasks = []
        @actors = []

        find_extensions
        load_extensions
      end

      def shutdown
        return nil if @loaded_extensions.nil?

        @subscription_tasks.each do |task|
          task[:threadpool].shutdown
          task[:threadpool].kill unless task[:threadpool].wait_for_termination(5)
        end

        @loop_tasks.each { |task| task[:running_class].cancel if task[:running_class].respond_to?(:cancel) }
        @once_tasks.each { |task| task[:running_class].cancel if task[:running_class].respond_to?(:cancel) }
        @timer_tasks.each { |task| task[:running_class].cancel if task[:running_class].respond_to?(:cancel) }
        @poll_tasks.each { |task| task[:running_class].cancel if task[:running_class].respond_to?(:cancel) }

        Legion::Logging.info 'Successfully shut down all actors'
      end

      def load_extensions
        @extensions ||= {}
        @loaded_extensions ||= []
        @extensions.each do |extension, values|
          if values.key(:enabled) && !values[:enabled]
            Legion::Logging.info "Skipping #{extension} because it's disabled"
            next
          end

          if Legion::Settings[:extensions].key?(extension.to_sym) && Legion::Settings[:extensions][extension.to_sym].key?(:enabled) && !Legion::Settings[:extensions][extension.to_sym][:enabled] # rubocop:disable Layout/LineLength
            next
          end

          unless load_extension(extension, values)
            Legion::Logging.warn("#{extension} failed to load")
            next
          end
          @loaded_extensions.push(extension)
          sleep(0.1)
        end
        Legion::Logging.info "#{@extensions.count} extensions loaded with subscription:#{@subscription_tasks.count},every:#{@timer_tasks.count},poll:#{@poll_tasks.count},once:#{@once_tasks.count},loop:#{@loop_tasks.count}"
      end

      def load_extension(extension, values) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
        return unless gem_load(values[:gem_name], extension)

        extension = Kernel.const_get(values[:extension_class])
        extension.extend Legion::Extensions::Core unless extension.singleton_class.included_modules.include? Legion::Extensions::Core

        min_version = Legion::Settings[:extensions][values[:extension_name]][:min_version] || nil
        Legion::Logging.fatal values if min_version.is_a?(String) && Gem::Version.new(values[:version]) >= Gem::Version.new(min_version)

        if extension.data_required? && Legion::Settings[:data][:connected] == false
          Legion::Logging.warn "#{values[:extension_name]} requires Legion::Data but isn't enabled, skipping"
          return false
        end

        if extension.cache_required? && Legion::Settings[:cache][:connected] == false
          Legion::Logging.warn "#{values[:extension_name]} requires Legion::Cache but isn't enabled, skipping"
          return false
        end

        if extension.crypt_required? && Legion::Settings[:crypt][:cs].nil?
          Legion::Logging.warn "#{values[:extension_name]} requires Legion::Crypt but isn't ready, skipping"
          return false
        end

        if extension.vault_required? && Legion::Settings[:crypt][:vault][:connected] == false
          Legion::Logging.warn "#{values[:extension_name]} requires Legion::Crypt::Vault but isn't enabled, skipping"
          return false
        end

        has_logger = extension.respond_to?(:log)
        extension.autobuild

        require 'legion/transport/messages/lex_register'
        Legion::Transport::Messages::LexRegister.new(function: 'save', opts: extension.runners).publish

        if extension.respond_to?(:meta_actors) && extension.meta_actors.is_a?(Array)
          extension.meta_actors.each do |_key, actor|
            extension.log.debug("hooking meta actor: #{actor}") if has_logger
            hook_actor(**actor)
          end
        end

        extension.actors.each do |_key, actor|
          extension.log.debug("hooking literal actor: #{actor}") if has_logger
          hook_actor(**actor)
        end
        extension.log.info "Loaded v#{extension::VERSION}"
      rescue StandardError => e
        Legion::Logging.error e.message
        Legion::Logging.error e.backtrace
        false
      end

      def hook_actor(extension:, extension_name:, actor_class:, size: 1, **opts)
        size = if Legion::Settings[:extensions].key?(extension_name.to_sym) && Legion::Settings[:extensions][extension_name.to_sym].key?(:workers)
                 Legion::Settings[:extensions][extension_name.to_sym][:workers]
               elsif size.is_a? Integer
                 size
               else
                 1
               end

        extension_hash = {
          extension:       extension,
          extension_name:  extension_name,
          actor_class:     actor_class,
          size:            size,
          fallback_policy: :abort,
          **opts
        }
        extension_hash[:running_class] = if actor_class.ancestors.include? Legion::Extensions::Actors::Subscription
                                           actor_class
                                         else
                                           actor_class.new
                                         end

        return if extension_hash[:running_class].respond_to?(:enabled?) && !extension_hash[:running_class].enabled?

        if actor_class.ancestors.include? Legion::Extensions::Actors::Every
          @timer_tasks.push(extension_hash)
        elsif actor_class.ancestors.include? Legion::Extensions::Actors::Once
          @once_tasks.push(extension_hash)
        elsif actor_class.ancestors.include? Legion::Extensions::Actors::Loop
          @loop_tasks.push(extension_hash)
        elsif actor_class.ancestors.include? Legion::Extensions::Actors::Poll
          @poll_tasks.push(extension_hash)
        elsif actor_class.ancestors.include? Legion::Extensions::Actors::Subscription
          extension_hash[:threadpool] = Concurrent::FixedThreadPool.new(size)
          size.times do
            extension_hash[:threadpool].post do
              klass = actor_class.new
              if klass.respond_to?(:async)
                klass.async.subscribe
              else
                klass.subscribe
              end
            end
          end
          @subscription_tasks.push(extension_hash)
        else
          Legion::Logging.fatal 'did not match any actor classes'
        end
      end

      def gem_load(gem_name, name)
        require "#{Gem::Specification.find_by_name(gem_name).gem_dir}/lib/legion/extensions/#{name}"
        true
      rescue LoadError => e
        Legion::Logging.error e.message
        Legion::Logging.error e.backtrace
        Legion::Logging.error "gem_path: #{gem_path}" unless gem_path.nil?
        false
      end

      def find_extensions
        @extensions ||= {}
        Gem::Specification.all_names.each do |gem|
          next unless gem[0..3] == 'lex-'

          lex = gem.split('-')
          @extensions[lex[1]] = { full_gem_name:   gem,
                                  gem_name:        "lex-#{lex[1]}",
                                  extension_name:  lex[1],
                                  version:         lex[2],
                                  extension_class: "Legion::Extensions::#{lex[1].split('_').collect(&:capitalize).join}" }
        end

        enabled = 0
        requested = 0

        Legion::Settings[:extensions].each do |extension, values|
          next if @extensions.key? extension.to_s
          next if values[:enabled] == false

          requested += 1
          next if values[:auto_install] == false
          next if ENV['_'].include? 'bundle'

          Legion::Logging.warn "#{extension} is missing, attempting to install automatically.."
          install = Gem.install("lex-#{extension}", values[:version])
          Legion::Logging.debug(install)
          lex = Gem::Specification.find_by_name("lex-#{extension}")

          @extensions[extension.to_s] = {
            full_gem_name:   "lex-#{extension}-#{lex.version}",
            gem_name:        "lex-#{extension}",
            extension_name:  extension.to_s,
            version:         lex.version,
            extension_class: "Legion::Extensions::#{extension.to_s.split('_').collect(&:capitalize).join}"
          }

          enabled += 1

        rescue StandardError, Gem::MissingSpecError => e
          Legion::Logging.error "Failed to auto install #{extension}, e: #{e.message}"
        end
        return true if requested == enabled

        Legion::Logging.warn "A total of #{requested - enabled} where skipped"
        if ENV.key?('_') && ENV['_'].include?('bundle')
          Legion::Logging.warn 'Please add them to your Gemfile since you are using bundler'
        else
          Legion::Logging.warn 'You must have auto_install_missing_lex set to true to auto install missing extensions'
        end
      end
    end
  end
end
