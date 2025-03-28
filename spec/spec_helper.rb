# frozen_string_literal: true

require "bundler/setup"
require "simplecov"
require "webmock/rspec"

SimpleCov.start do
  add_filter "/spec/"
end

require "gemini_craft"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset GeminiCraft configuration before each test
  config.before do
    GeminiCraft.reset_configuration
  end
end
