# frozen_string_literal: true

require 'rspec'
require 'simplecov'
SimpleCov.start
require 'bundler/setup'
require 'legion'
require 'legion/service'
require 'legion/logging'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
