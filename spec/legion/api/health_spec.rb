# frozen_string_literal: true

require 'spec_helper'
require 'legion/api/health'

RSpec.describe Legion::API::Health do
  before { Legion::Readiness.reset }
  after { Legion::Readiness.reset }

  describe '.assess' do
    context 'when an enabled, previously-healthy component has degraded' do
      before do
        Legion::Readiness.mark_ready(:transport)
        Legion::Readiness.mark_skipped(:cache)
        Legion::Readiness.mark_skipped(:data)
        allow(described_class).to receive(:transport_liveness).and_return([false, 'session_open: false'])
      end

      it 'reports degraded' do
        result = described_class.assess
        expect(result[:status]).to eq('degraded')
        expect(result[:components][:transport]).to eq(enabled: true, healthy: false, detail: 'session_open: false')
      end
    end

    context 'when all enabled components are healthy' do
      before do
        Legion::Readiness.mark_ready(:transport)
        Legion::Readiness.mark_ready(:cache)
        Legion::Readiness.mark_skipped(:data)
        allow(described_class).to receive(:transport_liveness).and_return([true, nil])
        allow(described_class).to receive(:cache_liveness).and_return([true, nil])
      end

      it 'reports ok' do
        result = described_class.assess
        expect(result[:status]).to eq('ok')
        expect(result[:components][:cache]).to eq(enabled: true, healthy: true)
      end
    end

    context 'when a component is skipped (disabled)' do
      before do
        Legion::Readiness.mark_ready(:transport)
        Legion::Readiness.mark_skipped(:cache)
        Legion::Readiness.mark_skipped(:data)
        allow(described_class).to receive(:transport_liveness).and_return([true, nil])
      end

      it 'does not degrade health for the disabled component' do
        result = described_class.assess
        expect(result[:status]).to eq('ok')
        expect(result[:components][:data]).to eq(enabled: false, healthy: nil)
      end

      it 'does not run the liveness check for a disabled component' do
        expect(described_class).not_to receive(:cache_liveness)
        described_class.assess
      end
    end

    context 'when a component has not finished booting (never marked ready)' do
      before do
        Legion::Readiness.mark_ready(:transport)
        allow(described_class).to receive(:transport_liveness).and_return([true, nil])
        # cache/data left unset (nil) — still booting, not enabled-and-healthy
      end

      it 'does not degrade health for a still-booting component' do
        result = described_class.assess
        expect(result[:status]).to eq('ok')
        expect(result[:components][:cache]).to eq(enabled: false, healthy: nil)
      end
    end
  end

  describe '.transport_liveness' do
    it 'returns healthy in lite mode without checking the session' do
      conn = class_double('Legion::Transport::Connection', lite_mode?: true)
      stub_const('Legion::Transport::Connection', conn)
      expect(described_class.transport_liveness).to eq([true, nil])
    end

    it 'returns unhealthy when the session is not open' do
      session = instance_double('session', open?: false)
      conn = class_double('Legion::Transport::Connection', lite_mode?: false, session: session)
      stub_const('Legion::Transport::Connection', conn)
      expect(described_class.transport_liveness).to eq([false, 'session_open: false'])
    end
  end
end
