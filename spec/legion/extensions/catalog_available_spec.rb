# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Catalog::Available do
  describe '.find' do
    it 'includes the Legion-native LLM hosted provider extensions' do
      expect(described_class.find('lex-llm-bedrock')).to include(
        name:     'lex-llm-bedrock',
        category: 'ai'
      )
      expect(described_class.find('lex-llm-azure-foundry')).to include(
        name:     'lex-llm-azure-foundry',
        category: 'ai'
      )
      expect(described_class.find('lex-llm-vertex')).to include(
        name:     'lex-llm-vertex',
        category: 'ai'
      )
    end

    it 'does not advertise lex-llm-gateway' do
      expect(described_class.find('lex-llm-gateway')).to be_nil
    end

    it 'does not advertise deprecated direct provider extensions' do
      %w[
        lex-azure-ai
        lex-bedrock
        lex-claude
        lex-foundry
        lex-gemini
        lex-ollama
        lex-openai
      ].each do |deprecated|
        expect(described_class.find(deprecated)).to be_nil, "expected #{deprecated} to be removed from catalog"
      end
    end
  end
end
