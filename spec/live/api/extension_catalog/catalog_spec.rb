# frozen_string_literal: true

RSpec.describe 'GET /api/extension_catalog' do
  subject(:response) { get('/extension_catalog') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'returns data as an array' do
    expect(response.body[:data]).to be_an(Array)
  end

  it 'contains at least one loaded extension' do
    expect(response.body[:data]).not_to be_empty
  end

  it 'each extension has required fields' do
    entry = response.body[:data].first
    expect(entry[:name]).to be_a(String)
    expect(entry[:state]).to be_a(String)
    expect(entry[:active_version]).to be_a(String)
  end

  it 'each extension includes reload metadata' do
    entry = response.body[:data].first
    expect(entry).to have_key(:reload_state)
    expect(entry).to have_key(:pending_reload)
    expect(entry).to have_key(:hot_reloadable)
  end

  it 'each extension includes tools and routes arrays' do
    entry = response.body[:data].first
    expect(entry[:tools]).to be_an(Array)
    expect(entry[:routes]).to be_an(Array)
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
