# frozen_string_literal: true

RSpec.describe 'GET /api/health' do
  subject(:response) { get('/health') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'includes data.status of ok' do
    expect(response.body[:data][:status]).to eq('ok')
  end

  it 'includes a version string' do
    expect(response.body[:data][:version]).to be_a(String)
    expect(response.body[:data][:version]).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it 'includes uptime_seconds as a number' do
    expect(response.body[:data][:uptime_seconds]).to be_a(Numeric)
    expect(response.body[:data][:uptime_seconds]).to be >= 0
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
