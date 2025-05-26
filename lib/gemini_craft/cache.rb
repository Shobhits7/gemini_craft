# frozen_string_literal: true

require "digest"

module GeminiCraft
  # Enhanced in-memory cache for API responses with automatic cleanup
  class Cache
    # Initialize the cache
    # @param config [GeminiCraft::Configuration] Configuration object
    def initialize(config)
      @config = config
      @store = {}
      @timestamps = {}
      @access_times = {}
      @mutex = Mutex.new
      @cleanup_thread = nil

      start_cleanup_thread if @config.cache_enabled
    end

    # Get a value from the cache
    # @param key [String] Cache key
    # @return [String, nil] Cached value or nil if not found/expired
    def get(key)
      @mutex.synchronize do
        return nil unless @store.key?(key)

        # Check if the entry has expired
        if expired?(key)
          remove_entry(key)
          return nil
        end

        # Update access time for LRU
        @access_times[key] = Time.now.to_i
        @store[key]
      end
    end

    # Set a value in the cache
    # @param key [String] Cache key
    # @param value [String] Value to cache
    def set(key, value)
      @mutex.synchronize do
        @store[key] = value
        current_time = Time.now.to_i
        @timestamps[key] = current_time
        @access_times[key] = current_time

        # Perform cleanup if cache is getting large
        cleanup_if_needed
      end
    end

    # Clear the entire cache
    def clear
      @mutex.synchronize do
        @store.clear
        @timestamps.clear
        @access_times.clear
      end
    end

    # Get cache statistics
    # @return [Hash] Cache statistics
    def stats
      @mutex.synchronize do
        {
          size: @store.size,
          oldest_entry: @timestamps.values.min,
          newest_entry: @timestamps.values.max,
          total_keys: @timestamps.keys
        }
      end
    end

    # Remove expired entries from the cache
    def cleanup
      @mutex.synchronize do
        current_time = Time.now.to_i
        expired_keys = []

        @timestamps.each do |key, timestamp|
          expired_keys << key if current_time - timestamp > @config.cache_ttl
        end

        expired_keys.each { |key| remove_entry(key) }
        expired_keys.size
      end
    end

    # Stop the cleanup thread (for testing)
    def stop_cleanup_thread
      return unless @cleanup_thread

      @cleanup_thread.kill
      @cleanup_thread = nil
    end

    private

    def expired?(key)
      return false unless @timestamps[key]

      Time.now.to_i - @timestamps[key] > @config.cache_ttl
    end

    def remove_entry(key)
      @store.delete(key)
      @timestamps.delete(key)
      @access_times.delete(key)
    end

    def cleanup_if_needed
      return if @store.size < 100 # Lower threshold for testing

      # Remove expired entries first
      cleanup

      # If still too large, remove least recently used entries
      return if @store.size < 100

      # Remove 50% of entries (LRU)
      lru_count = @store.size / 2
      lru_keys = @access_times.sort_by { |_, time| time }.first(lru_count).map(&:first)
      lru_keys.each { |key| remove_entry(key) }
    end

    def start_cleanup_thread
      @cleanup_thread = Thread.new do
        loop do
          sleep(@config.cache_ttl / 2) # Cleanup every half TTL period
          cleanup
        rescue StandardError => e
          # Log error if logger is available, otherwise silently continue
          Rails.logger.warn "[GeminiCraft::Cache] Cleanup error: #{e.message}" if defined?(Rails) && Rails.logger
        end
      end
    end
  end
end
