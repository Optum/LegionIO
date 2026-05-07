# frozen_string_literal: true

RSpec.describe 'GET /api/extensions' do
  subject(:response) { get('/extensions') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'returns loaded extensions as an array' do
    expect(response.body[:data]).to be_an(Array)
  end

  it 'has at least one extension loaded' do
    expect(response.body[:data]).not_to be_empty
  end
end
