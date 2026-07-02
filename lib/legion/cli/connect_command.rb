# frozen_string_literal: true

require 'thor'

module Legion
  module CLI
    class ConnectCommand < Thor
      namespace :connect

      PROVIDERS = %w[microsoft github google].freeze
      STATE_COLORS = { 'connected' => :green, 'revoked' => :red, 'not connected' => :yellow }.freeze

      desc 'microsoft', 'Connect a Microsoft account (OAuth2 delegated auth)'
      method_option :tenant_id,  type: :string, desc: 'Azure tenant ID'
      method_option :client_id,  type: :string, desc: 'Application client ID'
      method_option :scope,      type: :string, default: 'Calendars.Read OnlineMeetings.Read',
                                 desc: 'OAuth2 scopes (space-separated)'
      method_option :no_browser, type: :boolean, default: false, desc: 'Print URL instead of launching browser'
      def microsoft
        say 'Delegating to Teams OAuth2 browser auth...', :blue
        forwarded = ['teams']
        forwarded += ['--tenant_id', options[:tenant_id]] if options[:tenant_id]
        forwarded += ['--client_id', options[:client_id]] if options[:client_id]
        forwarded += ['--scopes', options[:scope]] if options[:scope]
        Legion::CLI::Auth.start(forwarded)
      end

      desc 'github', 'Connect a GitHub account (OAuth2 device flow)'
      method_option :client_id, type: :string, desc: 'GitHub OAuth App client ID'
      def github
        say 'GitHub connection not yet implemented.', :yellow
      end

      desc 'status', 'Show connection status for all providers'
      def status
        require 'legion/auth/token_manager'

        PROVIDERS.each do |provider|
          state = provider_state(provider)
          say "  #{provider}: #{state}", STATE_COLORS.fetch(state, :yellow)
        end
      end

      desc 'disconnect PROVIDER', 'Disconnect a provider account'
      def disconnect(provider)
        unless PROVIDERS.include?(provider)
          say "Unknown provider: #{provider}. Valid: #{PROVIDERS.join(', ')}", :red
          return
        end

        say "Disconnected #{provider} account.", :green
      end

      no_commands do
        # Microsoft delegated login writes tokens via the Entra TokenManager
        # (vault/local/memory), not the legacy Legion::Auth secret store — so
        # status for :microsoft must consult the Entra store to avoid always
        # reporting 'not connected' after a successful Teams/delegated login.
        def provider_state(provider)
          return microsoft_state if provider == 'microsoft'

          manager = Legion::Auth::TokenManager.new(provider: provider.to_sym)
          return 'connected' if manager.token_valid?
          return 'revoked' if manager.revoked?

          'not connected'
        end

        def microsoft_state
          return 'not connected' unless defined?(Legion::Extensions::Identity::Entra::Helpers::TokenManager)

          tm = Legion::Extensions::Identity::Entra::Helpers::TokenManager
          data = tm.token_data(:delegated, refresh: false)
          data && !tm.expired?(data) ? 'connected' : 'not connected'
        rescue StandardError
          'not connected'
        end
      end
    end
  end
end
