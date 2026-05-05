# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require 'sinatra/base'
require 'legion/api/helpers'
require 'legion/api/validators'
require 'legion/api/llm'
require 'legion/llm/types/tool_definition'

RSpec.describe 'LLM API client tool definitions' do
  include Rack::Test::Methods

  before(:all) do
    Legion::Logging.setup(log_level: 'fatal', level: 'fatal', trace: false)
    Legion::Settings.load(config_dir: File.expand_path('../../..', __dir__))
    loader = Legion::Settings.loader
    loader.settings[:client]     = { name: 'test-node', ready: true }
    loader.settings[:data]       = { connected: false }
    loader.settings[:transport]  = { connected: false }
    loader.settings[:extensions] = {}
  end

  let(:test_app) do
    Class.new(Sinatra::Base) do
      helpers Legion::API::Helpers
      helpers Legion::API::Validators

      set :show_exceptions, false
      set :raise_errors, false
      set :host_authorization, permitted: :any

      register Legion::API::Routes::Llm
    end
  end

  def app
    test_app
  end

  def build_tool(name, description = 'test tool', schema = nil)
    test_app.new!.instance_eval { build_client_tool_class(name, description, schema) }
  end

  it 'builds native Legion LLM tool definitions without RubyLLM' do
    hide_const('RubyLLM') if defined?(RubyLLM)

    tool = build_tool('web_fetch', 'Fetches a web page', { type: 'object', properties: { url: { type: 'string' } } })

    expect(tool).to be_a(Legion::LLM::Types::ToolDefinition)
    expect(tool.name).to eq('web_fetch')
    expect(tool.description).to eq('Fetches a web page')
    expect(tool.parameters).to eq({ type: 'object', properties: { url: { type: 'string' } } })
    expect(tool.source).to eq({ type: :client, executable: true })
  end

  it 'sanitizes client tool names through the native tool definition type' do
    tool = build_tool('client.tool/name!', 'Sanitized')

    expect(tool.name).to eq('client_toolname')
    expect(tool.source[:type]).to eq(:client)
  end

  it 'defaults missing schemas to an empty parameters object' do
    tool = build_tool('web_search', 'Searches the web', nil)

    expect(tool.parameters).to eq({})
  end
end
