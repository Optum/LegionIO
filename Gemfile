# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

def local_gem_version(path, version_file)
  version_path = File.expand_path(File.join(path, version_file), __dir__)
  return unless File.file?(version_path)

  version_source = File.read(version_path)
  version_source[/VERSION\s*=\s*['"]([^'"]+)['"]/, 1]
end

def local_gem_satisfies?(path, version_file, requirement)
  version = local_gem_version(path, version_file)
  version && Gem::Requirement.new(requirement).satisfied_by?(Gem::Version.new(version))
end

def local_gem_path(name, default_path, version_file, requirement)
  env_name = "#{name.upcase.tr('-', '_')}_PATH"
  env_path = ENV.fetch(env_name, nil)
  return env_path if env_path && File.exist?(File.expand_path(env_path, __dir__))

  return unless File.exist?(File.expand_path(default_path, __dir__))
  return unless local_gem_satisfies?(default_path, version_file, requirement)

  default_path
end

gem 'legion-apollo', path: '../legion-apollo' if File.exist?(File.expand_path('../legion-apollo', __dir__))
gem 'legion-data', path: '../legion-data' if File.exist?(File.expand_path('../legion-data', __dir__))
gem 'legion-logging', path: '../legion-logging' if File.exist?(File.expand_path('../legion-logging', __dir__))
gem 'legion-settings', path: '../legion-settings' if File.exist?(File.expand_path('../legion-settings', __dir__))
if (legion_tty_path = local_gem_path('legion-tty', '../legion-tty', 'lib/legion/tty/version.rb', '>= 0.5.4'))
  gem 'legion-tty', path: legion_tty_path
end

gem 'legion-gaia', path: '../legion-gaia' if File.exist?(File.expand_path('../legion-gaia', __dir__))
if (legion_llm_path = local_gem_path('legion-llm', '../legion-llm', 'lib/legion/llm/version.rb', '>= 0.8.47'))
  gem 'legion-llm', path: legion_llm_path
end
gem 'legion-mcp', path: '../legion-mcp' if File.exist?(File.expand_path('../legion-mcp', __dir__))

gem 'lex-kerberos'

gem 'lex-apollo', path: '../extensions/lex-apollo' if File.exist?(File.expand_path('../extensions/lex-apollo', __dir__))
gem 'lex-llm', path: '../extensions-ai/lex-llm' if File.exist?(File.expand_path('../extensions-ai/lex-llm', __dir__))
gem 'lex-llm-ledger', path: '../extensions-ai/lex-llm-ledger' if File.exist?(File.expand_path('../extensions-ai/lex-llm-ledger', __dir__))

%w[anthropic azure-foundry bedrock gemini mlx ollama openai vertex vllm].each do |provider|
  provider_path = "../extensions-ai/lex-llm-#{provider}"
  gem "lex-llm-#{provider}", path: provider_path if File.exist?(File.expand_path(provider_path, __dir__))
end

# gem 'lex-microsoft_teams', path: '../extensions/lex-microsoft_teams' if File.exist?(File.expand_path('../extensions/lex-microsoft_teams', __dir__))

gem 'pg'

gem 'kramdown', '>= 2.0'
gem 'mysql2'

group :test do
  gem 'graphql'
  gem 'lex-codegen'
  gem 'lex-eval'
  gem 'rack-test'
  gem 'rake'
  gem 'rspec'
  gem 'rubocop'
  gem 'rubocop-legion'
  gem 'rubocop-rspec'
  gem 'ruby_llm'
  gem 'simplecov'
end
