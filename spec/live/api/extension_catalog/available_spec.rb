# frozen_string_literal: true

RSpec.describe 'GET /api/extension_catalog/available' do
  subject(:response) { get('/extension_catalog/available') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'returns data as an array' do
    expect(response.body[:data]).to be_an(Array)
  end

  it 'contains available extensions' do
    expect(response.body[:data]).not_to be_empty
  end

  it 'each entry has name, category, and description' do
    entry = response.body[:data].first
    expect(entry[:name]).to be_a(String)
    expect(entry[:category]).to be_a(String)
    expect(entry[:description]).to be_a(String)
  end

  it 'includes known categories' do
    categories = response.body[:data].map { |e| e[:category] }.uniq
    expect(categories).to include('core')
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
