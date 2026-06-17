# frozen_string_literal: true

require 'spec_helper'
require 'sinatra/base'
require 'legion/api'

RSpec.describe Legion::API do
  let(:api_class) { Class.new(described_class) }

  it 'mounts legion-llm routes via library decoration during API construction' do
    source = File.read(File.expand_path('../../../lib/legion/api.rb', __dir__))

    expect(source).to include("mount_library_routes('llm', Legion::LLM::API, 'Legion::LLM::Routes')")
    expect(source).not_to include('register Routes::Llm')
  end

  it 'mounts legion-apollo routes as the primary apollo route owner during API construction' do
    source = File.read(File.expand_path('../../../lib/legion/api.rb', __dir__))

    expect(source).to include("mount_library_routes('apollo', Routes::Apollo, 'Legion::Apollo::Routes')")
    expect(source).not_to include('register Routes::Apollo')
  end

  describe '.mount_library_routes' do
    it 'prefers loaded library route modules and tracks them in discovery' do
      apollo_routes = Module.new
      stub_const('Legion::Apollo::Routes', apollo_routes)
      allow(api_class).to receive(:register)

      api_class.mount_library_routes('apollo', Legion::API::Routes::Apollo, 'Legion::Apollo::Routes')

      expect(api_class.router.library_routes['apollo']).to eq(apollo_routes)
      expect(api_class).to have_received(:register).with(apollo_routes)
    end

    it 'falls back to core routes when the library route module is unavailable' do
      allow(api_class).to receive(:register)
      allow(api_class).to receive(:constant_from_path).with('Legion::Apollo::Routes').and_return(nil)

      api_class.mount_library_routes('apollo', Legion::API::Routes::Apollo, 'Legion::Apollo::Routes')

      expect(api_class.router.library_routes).to be_empty
      expect(api_class).to have_received(:register).with(Legion::API::Routes::Apollo)
    end
  end

  describe '.register_library_routes' do
    it 'does not re-register the same route module twice' do
      allow(api_class).to receive(:register)
      routes_module = Module.new

      api_class.register_library_routes('test_gem', routes_module)
      api_class.register_library_routes('test_gem', routes_module)

      expect(api_class.router.library_routes['test_gem']).to eq(routes_module)
      expect(api_class).to have_received(:register).once.with(routes_module)
    end
  end
end
