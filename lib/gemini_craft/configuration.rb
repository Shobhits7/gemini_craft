# frozen_string_literal: true

module GeminiCraft
  # Configuration for the GeminiCraft gem
  class Configuration
    attr_accessor :api_key, :api_base_url, :model, :timeout, :cache_enabled, :cache_ttl, :max_retries,
                  :logger, :log_level, :streaming_enabled, :connection_pool_size, :keep_alive_timeout

    # Initialize a new configuration with default values
    def initialize
      @api_key = ENV.fetch("GEMINI_API_KEY", nil)
      @api_base_url = "https://generativelanguage.googleapis.com/v1beta"
      @model = "gemini-2.0-flash"
      @timeout = 30
      @cache_enabled = false
      @cache_ttl = 3600 # 1 hour in seconds
      @max_retries = 3
      @logger = nil
      @log_level = :info
      @streaming_enabled = false
      @connection_pool_size = 5
      @keep_alive_timeout = 30
    end

    # Validate that the configuration has required parameters
    # @raise [GeminiCraft::ConfigurationError] if the configuration is invalid
    def validate!
      raise ConfigurationError, "API key must be configured" unless api_key
      raise ConfigurationError, "Model must be configured" unless model

      validate_log_level!
      validate_timeouts!
    end

    private

    def validate_log_level!
      valid_levels = %i[debug info warn error fatal]
      return if valid_levels.include?(log_level)

      raise ConfigurationError, "Invalid log level: #{log_level}. Must be one of: #{valid_levels.join(", ")}"
    end

    def validate_timeouts!
      raise ConfigurationError, "Timeout must be positive" if timeout <= 0
      raise ConfigurationError, "Cache TTL must be positive" if cache_ttl <= 0
    end
  end

  # Error raised when configuration is invalid
  class ConfigurationError < Error; end
end
