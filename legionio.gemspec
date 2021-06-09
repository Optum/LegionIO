# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'legion/version'

Gem::Specification.new do |spec|
  spec.name = 'legionio'
  spec.version       = Legion::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = ''
  spec.description   = ''
  spec.homepage      = 'https://github.com/Optum/LegionIO'
  spec.license       = 'Apache-2.0'
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'

  spec.metadata = {
    'bug_tracker_uri'   => 'https://github.com/Optum/LegionIO/issues',
    'changelog_uri'     => 'https://github.com/Optum/LegionIO/src/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/Optum/LegionIO',
    'homepage_uri'      => 'https://github.com/Optum/LegionIO',
    'source_code_uri'   => 'https://github.com/Optum/LegionIO',
    'wiki_uri'          => 'https://github.com/Optum/LegionIO'
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.test_files = spec.files.select { |p| p =~ %r{^test/.*_test.rb} }

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.add_dependency 'concurrent-ruby', '>= 1.1.7'
  spec.add_dependency 'concurrent-ruby-ext', '>= 1.1.7'
  spec.add_dependency 'daemons', '>= 1.3.1'
  spec.add_dependency 'oj', '>= 3.10'
  spec.add_dependency 'thor', '>= 1'

  spec.add_dependency 'legion-cache', '>= 0.2.0'
  spec.add_dependency 'legion-crypt', '>= 0.2.0'
  spec.add_dependency 'legion-json', '>= 0.2.0'
  spec.add_dependency 'legion-logging', '>= 0.2.0'
  spec.add_dependency 'legion-settings', '>= 0.2.0'
  spec.add_dependency 'legion-transport', '>= 1.1.9'

  spec.add_dependency 'lex-node'

  spec.add_development_dependency 'legion-data'
end
