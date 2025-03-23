# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module GeminiCraft
  # Client for interacting with the Gemini API
  class Client
    attr_reader :config, :cache

    # Initialize a new client
    def initialize
      @config = GeminiCraft.configuration
      @config.validate!
      @cache = Cache.new(@config)
    end

    # Generate content using Gemini
    # @param text [String] The text prompt to send to Gemini
    # @param system_instruction [String, nil] Optional system instruction to guide the model
    # @param options [Hash] Additional options for the request
    # @return [String] The generated content
    def generate_content(text, system_instruction = nil, options = {})
      # Create cache key from the request parameters
      cache_key = generate_cache_key(text, system_instruction, options)

      # Check cache if enabled
      if @config.cache_enabled && (cached_response = @cache.get(cache_key))
        return cached_response
      end

      # Prepare request payload
      payload = build_payload(text, system_instruction, options)

      # Send request to API
      response = make_request("models/#{@config.model}:generateContent", payload)

      # Process response
      content = extract_content(response)

      # Cache response if enabled
      @cache.set(cache_key, content) if @config.cache_enabled

      content
    end

    private

    # Build the API request payload
    # @param text [String] The text prompt
    # @param system_instruction [String, nil] Optional system instruction
    # @param options [Hash] Additional options
    # @return [Hash] The request payload
    def build_payload(text, system_instruction, options)
      payload = {
        contents: [
          {
            parts: [
              {
                text: text
              }
            ]
          }
        ]
      }

      # Add system instruction if provided
      if system_instruction
        payload[:system_instruction] = {
          parts: [
            {
              text: system_instruction
            }
          ]
        }
      end

      # Merge additional options if provided
      payload.merge!(options) if options && !options.empty?

      payload
    end

    # Make a request to the Gemini API
    # @param endpoint [String] API endpoint
    # @param payload [Hash] Request payload
    # @return [Hash] Parsed response
    # @raise [GeminiCraft::APIError] If the API returns an error
    def make_request(endpoint, payload)
      response = connection.post(endpoint) do |req|
        req.params["key"] = @config.api_key
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(payload)
      end

      handle_response(response)
    rescue Faraday::Error => e
      raise APIError, "API request failed: #{e.message}"
    end

    # Set up a Faraday connection with retry logic
    # @return [Faraday::Connection] Configured connection
    def connection
      Faraday.new(url: @config.api_base_url) do |faraday|
        faraday.options.timeout = @config.timeout
        faraday.request :retry, max: @config.max_retries, interval: 0.5,
                                interval_randomness: 0.5, backoff_factor: 2,
                                exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
        faraday.adapter Faraday.default_adapter
      end
    end

    # Handle and parse the API response
    # @param response [Faraday::Response] The API response
    # @return [Hash] Parsed response body
    # @raise [GeminiCraft::APIError] If the API returns an error
    def handle_response(response)
      case response.status
      when 200
        JSON.parse(response.body)
      when 400..499
        error_body = begin
          JSON.parse(response.body)
        rescue StandardError
          { "error" => response.body }
        end
        raise APIError, "API client error (#{response.status}): #{error_body["error"]["message"] || "Unknown error"}"
      when 500..599
        raise APIError, "API server error (#{response.status}): The server encountered an error"
      else
        raise APIError, "Unknown API error (#{response.status})"
      end
    end

    # Extract content from the response
    # @param response [Hash] Parsed API response
    # @return [String] The extracted content
    # @raise [GeminiCraft::ResponseError] If the response format is unexpected
    def extract_content(response)
      candidates = response["candidates"]
      return "" if candidates.nil? || candidates.empty?

      content = candidates[0]["content"]
      return "" if content.nil?

      parts = content["parts"]
      return "" if parts.nil? || parts.empty?

      text = parts[0]["text"]
      text || ""
    rescue StandardError => e
      raise ResponseError, "Failed to extract content from response: #{e.message}"
    end

    # Generate a cache key from request parameters
    # @param text [String] The text prompt
    # @param system_instruction [String, nil] Optional system instruction
    # @param options [Hash] Additional options
    # @return [String] A unique cache key
    def generate_cache_key(text, system_instruction, options)
      key_parts = [
        @config.model,
        text,
        system_instruction,
        options.to_s
      ]

      # Create a deterministic string from the key parts
      Digest::SHA256.hexdigest(key_parts.join("--"))
    end
  end
end
