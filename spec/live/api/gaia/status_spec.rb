# frozen_string_literal: true

RSpec.describe 'GET /api/gaia/status' do
  subject(:response) { get('/gaia/status') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'reports started status' do
    expect(response.body[:data][:started]).to be(true).or be(false)
  end

  it 'includes the mode' do
    expect(response.body[:data][:mode]).to be_a(String)
  end

  it 'includes buffer_depth as a number' do
    expect(response.body[:data][:buffer_depth]).to be_a(Integer)
  end

  it 'includes active_channels as an array' do
    expect(response.body[:data][:active_channels]).to be_an(Array)
  end

  it 'includes tick_count and tick_mode' do
    expect(response.body[:data][:tick_count]).to be_a(Integer)
    expect(response.body[:data][:tick_mode]).to be_a(String)
  end

  it 'includes sensory_buffer details' do
    buffer = response.body[:data][:sensory_buffer]
    expect(buffer).to be_a(Hash)
    expect(buffer[:depth]).to be_a(Integer)
    expect(buffer[:max_capacity]).to be_a(Integer)
  end

  it 'includes phase_list as an array' do
    expect(response.body[:data][:phase_list]).to be_an(Array)
    expect(response.body[:data][:phase_list]).not_to be_empty
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
