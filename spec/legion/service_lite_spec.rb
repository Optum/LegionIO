# frozen_string_literal: true

require 'spec_helper'
require 'legion/service'

RSpec.describe Legion::Service do
  describe '#lite_mode?' do
    it 'returns true when LEGION_MODE is lite' do
      service = described_class.allocate
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('LEGION_MODE').and_return('lite')
      expect(service.lite_mode?).to be true
    end

    it 'returns true when settings mode is lite' do
      service = described_class.allocate
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('LEGION_MODE').and_return(nil)
      allow(Legion::Settings).to receive(:[]).and_call_original
      allow(Legion::Settings).to receive(:[]).with(:mode).and_return('lite')
      expect(service.lite_mode?).to be true
    end
  end

  describe '#setup_local_mode' do
    it 'marks dev mode through the public settings writer in lite mode' do
      service = described_class.allocate
      allow(Legion::Mode).to receive(:lite?).and_return(true)
      allow(service).to receive(:require).with('legion/transport/local')
      allow(service).to receive(:require).with('legion/crypt/mock_vault')

      expect(Legion::Settings).to receive(:set_prop).with(:dev, true)

      service.__send__(:setup_local_mode)
    end
  end
end
