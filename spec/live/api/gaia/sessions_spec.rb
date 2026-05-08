# frozen_string_literal: true

RSpec.describe 'GET /api/gaia/sessions' do
  subject(:response) { get('/gaia/sessions') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'includes count as an integer' do
    expect(response.body[:data][:count]).to be_a(Integer)
  end

  it 'includes active as a boolean' do
    expect(response.body[:data][:active]).to be(true).or be(false)
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
