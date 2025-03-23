# frozen_string_literal: true

require "digest"

module GeminiCraft
  # Simple in-memory cache for API responses
  class Cache
    # Initialize the cache
    # @param config [GeminiCraft::Configuration] Configuration object
    def initialize(config)
      @config = config
      @store = {}
      @timestamps = {}
    end

    # Get a value from the cache
    # @param key [String] Cache key
    # @return [String, nil] Cached value or nil if not found/expired
    def get(key)
      return nil unless @store.key?(key)

      # Check if the entry has expired
      if Time.now.to_i - @timestamps[key] > @config.cache_ttl
        @store.delete(key)
        @timestamps.delete(key)
        return nil
      end

      @store[key]
    end

    # Set a value in the cache
    # @param key [String] Cache key
    # @param value [String] Value to cache
    def set(key, value)
      @store[key] = value
      @timestamps[key] = Time.now.to_i
    end

    # Clear the entire cache
    def clear
      @store.clear
      @timestamps.clear
    end

    # Remove expired entries from the cache
    def cleanup
      current_time = Time.now.to_i
      @timestamps.each do |key, timestamp|
        if current_time - timestamp > @config.cache_ttl
          @store.delete(key)
          @timestamps.delete(key)
        end
      end
    end
  end
end
