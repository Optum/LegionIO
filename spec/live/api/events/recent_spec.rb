# frozen_string_literal: true

RSpec.describe 'GET /api/events/recent' do
  subject(:response) { get('/events/recent') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'returns data as an array' do
    expect(response.body[:data]).to be_an(Array)
  end

  it 'each event has required fields' do
    skip 'no events recorded yet' if response.body[:data].empty?

    entry = response.body[:data].first
    expect(entry[:event]).to be_a(String)
    expect(entry[:timestamp]).to be_a(String)
    expect(entry[:status]).to be_a(String)
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
