# frozen_string_literal: true

RSpec.describe 'GET /api/openapi.json' do
  subject(:response) { get('/openapi.json') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'declares OpenAPI 3.1.0' do
    expect(response.body[:openapi]).to eq('3.1.0')
  end

  it 'has info with title and version' do
    expect(response.body[:info][:title]).to eq('LegionIO REST API')
    expect(response.body[:info][:version]).not_to be_nil
  end

  it 'has paths' do
    expect(response.body[:paths]).to be_a(Hash)
    expect(response.body[:paths].size).to be > 0
  end

  it 'has components' do
    expect(response.body[:components]).to be_a(Hash)
  end

  it 'has tags' do
    expect(response.body[:tags]).to be_an(Array)
    expect(response.body[:tags]).not_to be_empty
  end

  it 'has security schemes defined' do
    expect(response.body[:security]).to be_an(Array)
    expect(response.body[:security]).not_to be_empty
  end
end
