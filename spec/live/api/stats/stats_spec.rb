# frozen_string_literal: true

RSpec.describe 'GET /api/stats' do
  subject(:response) { get('/stats') }

  it 'returns 200' do
    expect(response.status).to eq(200)
  end

  it 'returns data as a hash' do
    expect(response.body[:data]).to be_a(Hash)
  end

  it 'includes extensions stats' do
    extensions = response.body[:data][:extensions]
    expect(extensions).to be_a(Hash)
    expect(extensions[:loaded]).to be_a(Integer)
    expect(extensions[:running]).to be_a(Integer)
    expect(extensions[:actors]).to be_a(Integer)
  end

  it 'includes transport stats' do
    transport = response.body[:data][:transport]
    expect(transport).to be_a(Hash)
    expect(transport[:connected]).to be(true).or be(false)
    expect(transport[:connector]).to be_a(String)
  end

  it 'includes cache stats' do
    cache = response.body[:data][:cache]
    expect(cache).to be_a(Hash)
    expect(cache[:connected]).to be(true).or be(false)
  end

  it 'includes llm stats' do
    llm = response.body[:data][:llm]
    expect(llm).to be_a(Hash)
    expect(llm[:started]).to be(true).or be(false)
  end

  it 'includes api stats' do
    api = response.body[:data][:api]
    expect(api).to be_a(Hash)
    expect(api[:port]).to be_a(Integer)
    expect(api[:routes]).to be_a(Integer)
  end

  it 'includes gaia stats' do
    gaia = response.body[:data][:gaia]
    expect(gaia).to be_a(Hash)
    expect(gaia[:started]).to be(true).or be(false)
  end

  it 'includes meta with timestamp and node' do
    expect(response.body[:meta][:timestamp]).to be_a(String)
    expect(response.body[:meta][:node]).to be_a(String)
  end
end
