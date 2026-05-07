# frozen_string_literal: true

RSpec.describe 'GET /api/transport' do
  subject(:response) { get('/transport') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'reports connection status' do
    data = response.body[:data]
    expect(data[:connected]).to be(true).or be(false)
  end

  it 'includes session and channel open status' do
    data = response.body[:data]
    expect(data).to have_key(:session_open)
    expect(data).to have_key(:channel_open)
  end

  it 'reports the connector type' do
    data = response.body[:data]
    expect(data[:connector]).to be_a(String)
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
