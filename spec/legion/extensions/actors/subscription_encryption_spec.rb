# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Actors::Subscription do
  let(:actor) { described_class.allocate }
  let(:delivery_info) { { routing_key: 'lex.test.runner' } }

  before do
    allow(actor).to receive(:lex_name).and_return('test')
    allow(actor).to receive(:runner_name).and_return('runner')
  end

  describe '#process_message encrypted/cs handling' do
    it 'decrypts with a string-keyed iv header' do
      metadata = metadata_for(headers: { 'iv' => 'string-iv' })

      expect(Legion::Crypt).to receive(:decrypt).with('ciphertext', 'string-iv').and_return('{"ok":true}')

      message = actor.process_message('ciphertext', metadata, delivery_info)

      expect(message).to include(ok: true, iv: 'string-iv', routing_key: 'lex.test.runner')
    end

    it 'decrypts with a symbol-keyed iv header' do
      metadata = metadata_for(headers: { iv: 'symbol-iv' })

      expect(Legion::Crypt).to receive(:decrypt).with('ciphertext', 'symbol-iv').and_return('{"ok":true}')

      message = actor.process_message('ciphertext', metadata, delivery_info)

      expect(message).to include(ok: true, iv: 'symbol-iv', routing_key: 'lex.test.runner')
    end

    it 'dead-letters encrypted messages that are missing an iv before decrypting' do
      metadata = metadata_for(headers: {})

      expect(Legion::Crypt).not_to receive(:decrypt)

      expect do
        actor.process_message('ciphertext', metadata, delivery_info)
      end.to raise_error(
        Legion::Extensions::Actors::UnrecoverableMessageError,
        'encrypted/cs message missing iv header (test/runner)'
      )
    end

    it 'does not decrypt identity encoded messages' do
      metadata = metadata_for(content_encoding: 'identity', headers: { iv: 'ignored' })

      expect(Legion::Crypt).not_to receive(:decrypt)

      message = actor.process_message('{"ok":true}', metadata, delivery_info)

      expect(message).to include(ok: true, iv: 'ignored', routing_key: 'lex.test.runner')
    end
  end

  def metadata_for(content_encoding: 'encrypted/cs', content_type: 'application/json', headers: {})
    instance_double(
      Bunny::MessageProperties,
      content_encoding: content_encoding,
      content_type:     content_type,
      headers:          headers
    )
  end
end
