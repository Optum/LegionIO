# frozen_string_literal: true

RSpec.describe 'GET /api/llm/providers' do
  subject(:response) { get('/llm/providers') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'has a data key' do
    expect(response.body).to include(:data)
  end

  it 'has data.providers as an array' do
    expect(response.body[:data][:providers]).to be_an(Array)
  end

  it 'has data.summary.total >= 5' do
    expect(response.body[:data][:summary][:total]).to be >= 5
  end

  it 'has data.summary.native >= 5' do
    expect(response.body[:data][:summary][:native]).to be >= 5
  end

  it 'has data.summary.routing_enabled = true' do
    expect(response.body[:data][:summary][:routing_enabled]).to be true
  end
end
