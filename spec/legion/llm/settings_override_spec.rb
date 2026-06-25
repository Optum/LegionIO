# frozen_string_literal: true

require 'spec_helper'
require 'legion/llm'

RSpec.describe 'LegionIO LLM namespace settings override' do
  it 'enables use_namespaces via loader.settings override' do
    Legion::Settings.merge_settings('llm', Legion::LLM::Settings.default)
    Legion::Settings.loader.settings[:llm][:use_namespaces] = true

    expect(Legion::Settings[:llm][:use_namespaces]).to eq(true)
  end

  it 'preserves other api defaults after override' do
    Legion::Settings.merge_settings('llm', Legion::LLM::Settings.default)
    Legion::Settings.loader.settings[:llm][:use_namespaces] = true

    expect(Legion::Settings[:llm][:api][:auth][:enabled]).to eq(false)
    expect(Legion::Settings[:llm][:api][:auth][:api_keys]).to eq([])
  end
end
