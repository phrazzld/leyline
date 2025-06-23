# frozen_string_literal: true

require 'bundler/setup'

# Add lib directory to load path
lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

# Require our CLI components
require 'leyline/cli'
require 'leyline/cli/options'

# Require sync components
require 'leyline/sync/git_client'
require 'leyline/sync/file_syncer'

# Load shared examples
Dir[File.join(__dir__, 'support', 'shared_examples', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Use the expect syntax (not should)
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  # Mock framework configuration
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.allow_message_expectations_on_nil = false
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  # Run specs in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed

  # Don't capture stdout/stderr globally - let individual tests handle it

  # Performance test configuration
  config.before(:example, :performance) do
    # Disable verbose output during performance tests for cleaner results
    @original_verbose = $VERBOSE
    $VERBOSE = nil
  end

  config.after(:example, :performance) do
    $VERBOSE = @original_verbose
  end

  # Tag configuration for performance tests
  config.define_derived_metadata(file_path: %r{/spec/performance/}) do |metadata|
    metadata[:performance] = true
  end

  # Aggregate failures for performance tests to get complete picture
  config.define_derived_metadata(:performance) do |metadata|
    metadata[:aggregate_failures] = true
  end
end
