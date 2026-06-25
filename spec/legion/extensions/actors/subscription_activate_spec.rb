# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Legion::Extensions::Actors::Subscription#activate' do
  let(:actor) { Legion::Extensions::Actors::Subscription.allocate }
  let(:channel) { double('channel') }
  let(:queue_double) { double('queue', channel: channel) }
  let(:consumer_double) { double('consumer') }

  before do
    actor.instance_variable_set(:@queue, queue_double)
    actor.instance_variable_set(:@consumer, consumer_double)
    allow(actor).to receive(:lex_name).and_return('test_lex')
    allow(actor).to receive(:runner_name).and_return('test_runner')
    allow(actor).to receive(:log).and_return(double('log', warn: nil, info: nil, error: nil, debug: nil))
  end

  context 'when no consumer exists' do
    before { actor.instance_variable_set(:@consumer, nil) }

    it 'warns and returns without subscribing' do
      expect(queue_double).not_to receive(:subscribe_with)
      actor.activate
    end
  end

  context 'when the channel is open' do
    before { allow(channel).to receive(:open?).and_return(true) }

    it 'subscribes directly without re-preparing' do
      expect(actor).not_to receive(:prepare)
      expect(queue_double).to receive(:subscribe_with).with(consumer_double)
      actor.activate
    end
  end

  context 'when the channel is closed' do
    let(:fresh_channel) { double('fresh_channel') }
    let(:fresh_queue) { double('fresh_queue', channel: fresh_channel) }
    let(:fresh_consumer) { double('fresh_consumer') }

    before do
      allow(channel).to receive(:open?).and_return(false)
    end

    it 'calls prepare and retries subscribe on fresh channel' do
      allow(fresh_channel).to receive(:open?).and_return(true)
      allow(actor).to receive(:prepare) do
        actor.instance_variable_set(:@queue, fresh_queue)
        actor.instance_variable_set(:@consumer, fresh_consumer)
      end
      expect(fresh_queue).to receive(:subscribe_with).with(fresh_consumer)
      actor.activate
    end

    it 'logs and skips subscribe when re-prepare leaves channel closed' do
      allow(actor).to receive(:prepare) do
        actor.instance_variable_set(:@queue, fresh_queue)
        actor.instance_variable_set(:@consumer, fresh_consumer)
      end
      allow(fresh_channel).to receive(:open?).and_return(false)

      expect(fresh_queue).not_to receive(:subscribe_with)
      actor.activate
    end

    it 'logs and skips subscribe when re-prepare leaves no consumer' do
      allow(actor).to receive(:prepare) do
        actor.instance_variable_set(:@queue, fresh_queue)
        actor.instance_variable_set(:@consumer, nil)
      end
      allow(fresh_channel).to receive(:open?).and_return(true)

      expect(fresh_queue).not_to receive(:subscribe_with)
      actor.activate
    end
  end
end
