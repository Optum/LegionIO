# frozen_string_literal: true

require 'spec_helper'
require 'legion/llm'

RSpec.describe 'LegionIO LLM namespace settings override' do
  it 'sets use_namespaces to true in the merged LLM settings' do
    base = Legion::LLM::Settings.default
    merged = base.merge({ api: base[:api].merge({ use_namespaces: true }) })

    expect(merged[:api][:use_namespaces]).to eq(true)
  end

  it 'does not disturb other api defaults' do
    base = Legion::LLM::Settings.default
    merged = base.merge({ api: base[:api].merge({ use_namespaces: true }) })

    expect(merged[:api][:auth][:enabled]).to eq(false)
    expect(merged[:api][:auth][:api_keys]).to eq([])
  end
end
