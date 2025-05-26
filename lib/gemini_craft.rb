# frozen_string_literal: true

require_relative "gemini_craft/version"
require_relative "gemini_craft/error"
require_relative "gemini_craft/configuration"
require_relative "gemini_craft/client"
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
    #     config.streaming_enabled = true
    #     config.logger = Rails.logger
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
    # @param stream [Boolean] Whether to stream the response
    # @return [String, Enumerator] The generated content or stream enumerator
    def generate_content(text, system_instruction = nil, options = {}, stream: false)
      client.generate_content(text, system_instruction, options, stream: stream)
    end

    # Generate content with function calling support
    # @param text [String] The text prompt
    # @param functions [Array<Hash>] Available functions for the model to call
    # @param system_instruction [String, nil] Optional system instruction
    # @param options [Hash] Additional options
    # @return [Hash] Response including function calls if any
    def generate_with_functions(text, functions, system_instruction = nil, options = {})
      client.generate_with_functions(text, functions, system_instruction, options)
    end

    # Generate streaming content
    # @param text [String] The text prompt to send to Gemini
    # @param system_instruction [String, nil] Optional system instruction
    # @param options [Hash] Additional options
    # @return [Enumerator] Stream enumerator
    def stream_content(text, system_instruction = nil, options = {})
      generate_content(text, system_instruction, options, stream: true)
    end

    # Reset the configuration to defaults
    def reset_configuration
      @configuration = Configuration.new
    end

    # Get cache statistics
    # @return [Hash] Cache statistics
    def cache_stats
      client.cache.stats
    end

    # Clear the cache
    def clear_cache
      client.cache.clear
    end
  end
end
