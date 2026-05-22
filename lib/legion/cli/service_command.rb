# frozen_string_literal: true

require 'open3'
require 'rbconfig'
require 'thor'
require 'legion/cli/output'

module Legion
  module CLI
    class ServiceCommand < Thor
      namespace 'service'

      def self.exit_on_failure?
        true
      end

      class_option :json,     type: :boolean, default: false, desc: 'Output as JSON'
      class_option :no_color, type: :boolean, default: false, desc: 'Disable color output'

      SERVICE_LABEL = 'homebrew.mxcl.legionio'

      desc 'start', 'Start the Legion launchd service'
      long_desc <<~DESC
        Starts the Legion background service via launchd. On macOS 26+ (Tahoe),
        uses launchctl kickstart to ensure immediate process spawn after bootstrap.
      DESC
      def start
        out = Output::Formatter.new(json: options[:json], color: !options[:no_color])
        ensure_macos!(out)

        plist = plist_path
        unless File.exist?(plist)
          out.error("Service plist not found at #{plist}")
          out.info('Run: brew install legionio')
          raise SystemExit, 1
        end

        uid = ::Process.uid
        target = "gui/#{uid}"

        if service_loaded?(target)
          out.info('Service already loaded, kicking...')
        else
          _, status = Open3.capture2e('launchctl', 'bootstrap', target, plist)
          out.warn('bootstrap failed (may already be loaded), attempting kickstart anyway') unless status.success?
        end

        _, status = Open3.capture2e('launchctl', 'kickstart', '-k', "#{target}/#{SERVICE_LABEL}")
        if status.success?
          out.success('Legion service started')
        else
          out.error('Failed to kickstart Legion service')
          raise SystemExit, 1
        end

        poll_ready(out)
      end

      desc 'stop', 'Stop the Legion launchd service'
      def stop
        out = Output::Formatter.new(json: options[:json], color: !options[:no_color])
        ensure_macos!(out)

        uid = ::Process.uid
        target = "gui/#{uid}"

        _, status = Open3.capture2e('launchctl', 'bootout', "#{target}/#{SERVICE_LABEL}")
        if status.success?
          out.success('Legion service stopped')
        else
          out.warn('Service was not loaded (already stopped?)')
        end
      end

      desc 'restart', 'Restart the Legion launchd service'
      def restart
        out = Output::Formatter.new(json: options[:json], color: !options[:no_color])
        ensure_macos!(out)

        uid = ::Process.uid
        target = "gui/#{uid}"

        Open3.capture2e('launchctl', 'bootout', "#{target}/#{SERVICE_LABEL}")
        sleep 1

        plist = plist_path
        Open3.capture2e('launchctl', 'bootstrap', target, plist) if File.exist?(plist)

        _, status = Open3.capture2e('launchctl', 'kickstart', '-k', "#{target}/#{SERVICE_LABEL}")
        if status.success?
          out.success('Legion service restarted')
        else
          out.error('Failed to restart Legion service')
          raise SystemExit, 1
        end

        poll_ready(out)
      end

      desc 'status', 'Show Legion launchd service status'
      def status
        out = Output::Formatter.new(json: options[:json], color: !options[:no_color])
        ensure_macos!(out)

        uid = ::Process.uid
        target = "gui/#{uid}"
        output, status = Open3.capture2e('launchctl', 'print', "#{target}/#{SERVICE_LABEL}")

        unless status.success?
          out.info('Service is not loaded')
          return
        end

        state = output[/state = (.+)/, 1] || 'unknown'
        pid = output[/pid = (\d+)/, 1]
        runs = output[/runs = (\d+)/, 1]

        if options[:json]
          puts Legion::JSON.dump({ state: state, pid: pid&.to_i, runs: runs&.to_i })
        else
          out.info("State: #{state}")
          out.info("PID: #{pid}") if pid
          out.info("Runs: #{runs}") if runs
        end
      end

      private

      def ensure_macos!(out)
        return if RbConfig::CONFIG['host_os'] =~ /darwin/

        out.error('The service command is only available on macOS (uses launchd)')
        raise SystemExit, 1
      end

      def plist_path
        File.expand_path("~/Library/LaunchAgents/#{SERVICE_LABEL}.plist")
      end

      def service_loaded?(target)
        _, status = Open3.capture2e('launchctl', 'print', "#{target}/#{SERVICE_LABEL}")
        status.success?
      end

      def poll_ready(out, port: 4567, timeout: 15)
        require 'net/http'
        deadline = ::Time.now + timeout
        until ::Time.now > deadline
          begin
            resp = Net::HTTP.get_response(URI("http://localhost:#{port}/api/ready"))
            if resp.is_a?(Net::HTTPSuccess)
              out.success("Daemon ready on port #{port}")
              return
            end
          rescue StandardError
            # not ready yet
          end
          sleep 1
        end
        out.info('Service started but not yet ready (boot in progress)')
      end
    end
  end
end
