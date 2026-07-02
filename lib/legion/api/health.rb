# frozen_string_literal: true

module Legion
  class API < Sinatra::Base
    # Subsystem health assessment for GET /api/health.
    #
    # A component degrades health ONLY if it is both:
    #   1. enabled — Legion::Readiness.status[c] == true (Service marks a
    #      component ready only when its config flag is on AND setup succeeded).
    #      :skipped (disabled) and false/nil (never booted / still booting) are
    #      NOT enabled-and-previously-healthy, so they never fail health.
    #   2. currently unhealthy — its live liveness check now returns false.
    #
    # This prevents both false negatives (200 while transport can't process
    # messages) and false positives (503 for a subsystem that was never
    # configured or hasn't finished booting).
    module Health
      COMPONENTS = %i[transport cache data].freeze

      class << self
        # Returns { status:, components: { name => { enabled:, healthy:, detail? } } }
        def assess
          components = COMPONENTS.to_h { |name| [name, component_health(name)] }
          degraded = components.any? { |_name, c| c[:enabled] && c[:healthy] == false }
          { status: degraded ? 'degraded' : 'ok', components: components }
        end

        def component_health(name)
          enabled = Legion::Readiness.status[name] == true
          return { enabled: false, healthy: nil } unless enabled

          healthy, detail = send("#{name}_liveness")
          info = { enabled: true, healthy: healthy }
          info[:detail] = detail if detail && !healthy
          info
        end

        # --- liveness checks: [healthy_boolean, detail_string_or_nil] ---

        def transport_liveness
          conn = Legion::Transport::Connection
          return [true, nil] if conn.respond_to?(:lite_mode?) && conn.lite_mode?

          session = conn.session
          open = session.respond_to?(:open?) && session.open?
          [open, open ? nil : 'session_open: false']
        rescue StandardError => e
          [false, e.message]
        end

        def cache_liveness
          return [true, nil] unless defined?(Legion::Cache)

          connected = Legion::Cache.connected?
          [connected, connected ? nil : 'cache not connected']
        rescue StandardError => e
          [false, e.message]
        end

        def data_liveness
          connected = begin
            Legion::Settings[:data][:connected] == true
          rescue StandardError
            false
          end
          [connected, connected ? nil : 'data not connected']
        rescue StandardError => e
          [false, e.message]
        end
      end
    end
  end
end
