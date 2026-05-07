# frozen_string_literal: true

RSpec.describe 'GET /api/gaia/buffer' do
  subject(:response) { get('/gaia/buffer') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'includes depth as an integer' do
    expect(response.body[:data][:depth]).to be_a(Integer)
  end

  it 'includes empty as a boolean' do
    expect(response.body[:data][:empty]).to be(true).or be(false)
  end

  it 'includes max_size as an integer' do
    expect(response.body[:data][:max_size]).to be_a(Integer)
    expect(response.body[:data][:max_size]).to be > 0
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
