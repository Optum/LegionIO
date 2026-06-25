# frozen_string_literal: true

RSpec.describe 'GET /api/ready' do
  subject(:response) { get('/ready') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'reports ready as true' do
    expect(response.body[:data][:ready]).to be true
  end

  it 'includes a components hash' do
    components = response.body[:data][:components]
    expect(components).to be_a(Hash)
    expect(components).not_to be_empty
  end

  it 'has all core components marked as true' do
    components = response.body[:data][:components]
    %i[settings transport extensions api].each do |component|
      expect(components[component]).to be(true), "expected #{component} to be true"
    end
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
