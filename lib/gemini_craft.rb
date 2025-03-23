# frozen_string_literal: true

require_relative "gemini_craft/version"

module GeminiCraft
  class Error < StandardError; end
  # Your code goes here...
end
# frozen_string_literal: true

require_relative "gemini_craft/configuration"
require_relative "gemini_craft/client"
require_relative "gemini_craft/error"
require_relative "gemini_craft/cache"

# GeminiCraft is a Ruby gem for generating content using Google's Gemini AI
module GeminiCraft
  class << self
    attr_writer :configuration

    # Returns the current configuration
    # @return [GeminiCraft::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure the gem by providing a block
    # @example
    #   GeminiCraft.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.model = "gemini-2.0-flash"
    #     config.cache_enabled = true
    #   end
    # @yield [config] The configuration object
    def configure
      yield(configuration)
    end

    # Create a new client instance
    # @return [GeminiCraft::Client]
    def client
      Client.new
    end

    # Generate content using Gemini
    # @param text [String] The text prompt to send to Gemini
    # @param system_instruction [String, nil] Optional system instruction to guide the model
    # @param options [Hash] Additional options for the request
    # @return [String] The generated content
    def generate_content(text, system_instruction = nil, options = {})
      client.generate_content(text, system_instruction, options)
    end

    # Reset the configuration to defaults
    def reset_configuration
      @configuration = Configuration.new
    end
  end
end
