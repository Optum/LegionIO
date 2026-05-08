# frozen_string_literal: true

require 'bundler/setup'
require 'faraday'
require 'faraday/net_http'
require 'json'

module LiveHelpers
  def api(path = '')
    base = ENV.fetch('LEGION_API_URL', 'http://localhost:4567')
    "#{base}/api#{path}"
  end

  def client
    @client ||= Faraday.new do |f|
      f.request :json
      f.response :json, parser_options: { symbolize_names: true }
      f.adapter Faraday.default_adapter
    end
  end

  def get(path)
    client.get(api(path))
  end

  def post(path, body = {})
    client.post(api(path), body)
  end
end

RSpec.configure do |config|
  config.include LiveHelpers

  config.before(:suite) do
    url = ENV.fetch('LEGION_API_URL', 'http://localhost:4567')
    begin
      resp = Faraday.get("#{url}/api/ready")
      unless resp.status == 200
        warn "Legion daemon at #{url} returned #{resp.status} on /api/ready"
        abort 'Daemon not ready. Start it with: legionio start'
      end
    rescue Faraday::ConnectionFailed
      abort "Cannot connect to Legion daemon at #{url}. Start it with: legionio start"
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.order = :defined
end
