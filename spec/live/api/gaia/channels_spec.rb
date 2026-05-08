# frozen_string_literal: true

RSpec.describe 'GET /api/gaia/channels' do
  subject(:response) { get('/gaia/channels') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'returns data with channels array and count' do
    data = response.body[:data]
    expect(data[:channels]).to be_an(Array)
    expect(data[:count]).to be_a(Integer)
  end

  it 'count matches channels array length' do
    data = response.body[:data]
    expect(data[:count]).to eq(data[:channels].length)
  end

  it 'each channel has id, started, capabilities, and type' do
    skip 'no channels configured' if response.body[:data][:channels].empty?

    channel = response.body[:data][:channels].first
    expect(channel[:id]).to be_a(String)
    expect(channel[:started]).to be(true).or be(false)
    expect(channel[:capabilities]).to be_an(Array)
    expect(channel[:type]).to be_a(String)
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
