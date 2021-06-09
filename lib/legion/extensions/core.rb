require_relative 'builders/actors'
require_relative 'builders/helpers'
require_relative 'builders/runners'

require_relative 'helpers/core'
require_relative 'helpers/task'
require_relative 'helpers/logger'
require_relative 'helpers/lex'
require_relative 'helpers/transport'
require_relative 'helpers/data'
require_relative 'helpers/cache'

require_relative 'actors/base'
require_relative 'actors/every'
require_relative 'actors/loop'
require_relative 'actors/once'
require_relative 'actors/poll'
require_relative 'actors/subscription'
require_relative 'actors/nothing'

module Legion
  module Extensions
    module Core
      include Legion::Extensions::Helpers::Transport
      include Legion::Extensions::Helpers::Lex

      include Legion::Extensions::Builder::Runners
      include Legion::Extensions::Builder::Helpers
      include Legion::Extensions::Builder::Actors

      def autobuild
        @actors = {}
        @meta_actors = {}
        @runners = {}
        @helpers = []

        @queues = {}
        @exchanges = {}
        @messages = {}
        build_settings
        build_transport
        build_data if Legion::Settings[:data][:connected] && data_required?
        build_helpers
        build_runners
        build_actors
      end

      def data_required?
        false
      end

      def transport_required?
        true
      end

      def cache_required?
        false
      end

      def crypt_required?
        false
      end

      def vault_required?
        false
      end

      def build_data
        auto_generate_data
        lex_class::Data.build
      end

      def build_transport
        if File.exist? "#{extension_path}/transport/autobuild.rb"
          require "#{extension_path}/transport/autobuild"
          extension_class::Transport::AutoBuild.build
          log.warn 'still using transport::autobuild, please upgrade'
        elsif File.exist? "#{extension_path}/transport.rb"
          require "#{extension_path}/transport"
          extension_class::Transport.build
        else
          auto_generate_transport
          extension_class::Transport.build
        end
      end

      def build_settings
        if Legion::Settings[:extensions].key?(lex_name.to_sym)
          Legion::Settings[:default_extension_settings].each do |key, value|
            Legion::Settings[:extensions][lex_name.to_sym][key.to_sym] = if Legion::Settings[:extensions][lex_name.to_sym].key?(key.to_sym)
                                                                           value.merge(Legion::Settings[:extensions][lex_name.to_sym][key.to_sym])
                                                                         else
                                                                           value
                                                                         end
          end
        else
          Legion::Settings[:extensions][lex_name.to_sym] = Legion::Settings[:default_extension_settings]
        end

        default_settings.each do |key, value|
          Legion::Settings[:extensions][lex_name.to_sym][key.to_sym] = if Legion::Settings[:extensions][lex_name.to_sym].key?(key.to_sym)
                                                                         value.merge(Legion::Settings[:extensions][lex_name.to_sym][key.to_sym])
                                                                       else
                                                                         value
                                                                       end
        end
      end

      def default_settings
        {}
      end

      def auto_generate_transport
        require 'legion/extensions/transport'
        log.debug 'running meta magic to generate a transport base class'
        return if Kernel.const_defined? "#{lex_class}::Transport"

        Kernel.const_get(lex_class.to_s).const_set('Transport', Module.new { extend Legion::Extensions::Transport })
      end

      def auto_generate_data
        require 'legion/extensions/data'
        log.debug 'running meta magic to generate a data base class'
        Kernel.const_get(lex_class.to_s).const_set('Data', Module.new { extend Legion::Extensions::Data })
      rescue StandardError => e
        log.error e.message
        log.error e.backtrace
      end
    end
  end
end
