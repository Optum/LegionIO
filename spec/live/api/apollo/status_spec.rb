# frozen_string_literal: true

RSpec.describe 'GET /api/apollo/status' do
  subject(:response) { get('/apollo/status') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'includes available as a boolean' do
    expect(response.body[:data][:available]).to be(true).or be(false)
  end

  it 'includes data_connected as a boolean' do
    expect(response.body[:data][:data_connected]).to be(true).or be(false)
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
