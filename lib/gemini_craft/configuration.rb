# frozen_string_literal: true

module GeminiCraft
  # Configuration for the GeminiCraft gem
  class Configuration
    attr_accessor :api_key, :api_base_url, :model, :timeout, :cache_enabled, :cache_ttl, :max_retries

    # Initialize a new configuration with default values
    def initialize
      @api_key = ENV.fetch("GEMINI_API_KEY", nil)
      @api_base_url = "https://generativelanguage.googleapis.com/v1beta"
      @model = "gemini-2.0-flash"
      @timeout = 30
      @cache_enabled = false
      @cache_ttl = 3600 # 1 hour in seconds
      @max_retries = 3
    end

    # Validate that the configuration has required parameters
    # @raise [GeminiCraft::ConfigurationError] if the configuration is invalid
    def validate!
      raise ConfigurationError, "API key must be configured" unless api_key
      raise ConfigurationError, "Model must be configured" unless model
    end
  end

  # Error raised when configuration is invalid
  class ConfigurationError < Error; end
end
