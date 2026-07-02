# frozen_string_literal: true

require_relative 'api_spec_helper'

RSpec.describe 'Health and Readiness API' do
  include Rack::Test::Methods

  def app
    Legion::API
  end

  before(:all) { ApiSpecSetup.configure_settings }

  describe 'GET /api/health' do
    after { Legion::Readiness.reset }

    it 'returns ok status when no enabled subsystem is degraded' do
      Legion::Readiness.reset
      get '/api/health'
      expect(last_response.status).to eq(200)
      body = Legion::JSON.load(last_response.body)
      expect(body[:data][:status]).to eq('ok')
      expect(body[:data][:version]).to eq(Legion::VERSION)
      expect(body[:data][:uptime_seconds]).to be_an(Integer)
      expect(body[:data][:uptime]).to eq(body[:data][:uptime_seconds])
      expect(body[:data][:components]).to have_key(:transport)
    end

    it 'returns 503 degraded when an enabled subsystem has broken' do
      Legion::Readiness.reset
      Legion::Readiness.mark_ready(:transport)
      allow(Legion::API::Health).to receive(:transport_liveness).and_return([false, 'session_open: false'])

      get '/api/health'
      expect(last_response.status).to eq(503)
      body = Legion::JSON.load(last_response.body)
      expect(body[:data][:status]).to eq('degraded')
      expect(body[:data][:components][:transport]).to include(enabled: true, healthy: false)
    end
  end

  describe 'GET /api/ready' do
    it 'returns readiness with component status' do
      get '/api/ready'
      body = Legion::JSON.load(last_response.body)
      expect(body[:data]).to have_key(:ready)
      expect(body[:data]).to have_key(:components)
    end
  end
end
