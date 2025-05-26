# lib/gemini_craft/client.rb - FIXED STREAMING

# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module GeminiCraft
  class Client
    attr_reader :config, :cache, :logger

    def initialize
      @config = GeminiCraft.configuration
      @config.validate!
      @cache = Cache.new(@config)
      @logger = setup_logger
    end

    def generate_content(text, system_instruction = nil, options = {}, stream: false)
      log(:info, "Generating content", { model: @config.model, stream: stream })

      cache_key = generate_cache_key(text, system_instruction, options) unless stream

      if !stream && @config.cache_enabled && (cached_response = @cache.get(cache_key))
        log(:debug, "Cache hit", { cache_key: cache_key })
        return cached_response
      end

      payload = build_payload(text, system_instruction, options, stream: stream)

      if stream
        generate_streaming_content(payload)
      else
        generate_standard_content(payload, cache_key)
      end
    rescue StandardError => e
      log(:error, "Content generation failed", { error: e.message })
      raise
    end

    def generate_with_functions(text, functions, system_instruction = nil, options = {})
      log(:info, "Generating content with functions", { function_count: functions.size })

      payload = build_payload(text, system_instruction, options)
      payload[:tools] = [{ function_declarations: functions }]

      response = make_request("models/#{@config.model}:generateContent", payload)
      process_function_response(response)
    end

    private

    def setup_logger
      return @config.logger if @config.logger
      return Logger.new(IO::NULL) unless defined?(Rails)

      Rails.logger
    rescue StandardError
      Logger.new(IO::NULL)
    end

    def log(level, message, metadata = {})
      return unless @logger.respond_to?(level)

      log_message = "[GeminiCraft] #{message}"
      log_message += " #{metadata.inspect}" unless metadata.empty?

      @logger.send(level, log_message)
    end

    def generate_standard_content(payload, cache_key)
      response = make_request("models/#{@config.model}:generateContent", payload)
      content = extract_content(response)

      if @config.cache_enabled && cache_key
        @cache.set(cache_key, content)
        log(:debug, "Response cached", { cache_key: cache_key })
      end

      content
    end

    def generate_streaming_content(payload)
      Enumerator.new do |yielder|
        # Remove stream flag from payload
        streaming_payload = payload.dup
        streaming_payload.delete(:stream)

        # Use streamGenerateContent endpoint with alt=sse
        streaming_connection.post("models/#{@config.model}:streamGenerateContent") do |req|
          req.params["key"] = @config.api_key
          req.params["alt"] = "sse"
          req.headers["Content-Type"] = "application/json"
          req.headers["Accept"] = "text/event-stream"
          req.body = JSON.generate(streaming_payload)

          # Process each chunk as it arrives
          req.options.on_data = proc do |chunk, _overall_received_bytes, _env|
            process_streaming_chunk(chunk, yielder)
          end
        end
      end
    end

    def process_streaming_chunk(chunk, yielder)
      StreamingProcessor.new(self).process_chunk(chunk) { |content| yielder << content }
    rescue StandardError => e
      log(:error, "Streaming error", { error: e.message })
      raise StreamingError, "Streaming failed: #{e.message}"
    end

    def handle_streaming_response(response)
      # Handle final streaming response if there are any errors
      return if [200, 204].include?(response.status)

      error_body = response.body.empty? ? "Unknown streaming error" : response.body
      raise APIError, "Streaming request failed (#{response.status}): #{error_body}"
    end

    def process_function_response(response)
      FunctionResponseProcessor.new.process(response)
    end

    def build_payload(text, system_instruction, options, stream: false)
      PayloadBuilder.new.build(text, system_instruction, options, stream: stream)
    end

    def make_request(endpoint, payload)
      log(:debug, "Making API request", { endpoint: endpoint })

      response = connection.post(endpoint) do |req|
        req.params["key"] = @config.api_key
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(payload)
      end

      ResponseHandler.new(self).handle_response(response)
    rescue Faraday::TimeoutError => e
      raise TimeoutError, "Request timed out: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      raise ConnectionError, "Connection failed: #{e.message}"
    rescue Faraday::Error => e
      raise APIError, "API request failed: #{e.message}"
    end

    def connection
      @connection ||= ConnectionBuilder.new(@config).build_connection
    end

    # FIXED: Separate connection for streaming to handle SSE properly
    def streaming_connection
      @streaming_connection ||= StreamingConnectionBuilder.new(@config).build_connection
    end

    def extract_content(response)
      ContentExtractor.new.extract(response)
    rescue StandardError => e
      raise ResponseError, "Failed to extract content from response: #{e.message}"
    end

    def generate_cache_key(text, system_instruction, options)
      CacheKeyGenerator.new(@config.model).generate(text, system_instruction, options)
    end
  end

  class PayloadBuilder
    def build(text, system_instruction, options, stream: false)
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

      if system_instruction
        payload[:system_instruction] = {
          parts: [
            {
              text: system_instruction
            }
          ]
        }
      end

      # Don't include stream flag in payload for SSE streaming
      # payload[:stream] = true if stream

      payload.merge!(options) if options && !options.empty?
      payload
    end
  end

  class StreamingProcessor
    def initialize(client)
      @client = client
    end

    def process_chunk(chunk)
      lines = chunk.split(/\r?\n/)

      lines.each do |line|
        next unless line.start_with?("data: ")

        json_data = line[6..].strip
        next if json_data.empty? || json_data == "[DONE]"

        begin
          data = JSON.parse(json_data)
          content = extract_streaming_content(data)
          yield(content) unless content.empty?
        rescue JSON::ParserError
          @client.send(:log, :debug, "Skipping invalid JSON chunk", { chunk: json_data[0..50] })
        end
      end
    end

    private

    def extract_streaming_content(data)
      candidates = data["candidates"]
      return "" if candidates.nil? || candidates.empty?

      candidate = candidates.first
      content = candidate["content"]
      return "" if content.nil?

      parts = content["parts"]
      return "" if parts.nil? || parts.empty?

      parts.first["text"] || ""
    rescue StandardError
      ""
    end
  end

  class FunctionResponseProcessor
    def process(response)
      candidates = response["candidates"]
      return { content: "", function_calls: [] } if candidates.nil? || candidates.empty?

      candidate = candidates.first
      content_parts = candidate.dig("content", "parts") || []

      text_parts = []
      function_calls = []

      content_parts.each do |part|
        if part["text"]
          text_parts << part["text"]
        elsif part["functionCall"]
          function_calls << {
            name: part["functionCall"]["name"],
            args: part["functionCall"]["args"] || {}
          }
        end
      end

      {
        content: text_parts.join(" "),
        function_calls: function_calls
      }
    end
  end

  class ResponseHandler
    def initialize(client)
      @client = client
    end

    def handle_response(response)
      case response.status
      when 200
        JSON.parse(response.body)
      when 400
        handle_client_error(response, "Bad Request")
      when 401
        raise AuthenticationError, "Invalid API key or authentication failed"
      when 403
        raise AuthorizationError, "Access forbidden - check your API permissions"
      when 404
        raise NotFoundError, "Model or endpoint not found"
      when 429
        raise RateLimitError, "Rate limit exceeded - please slow down your requests"
      when 500..599
        raise ServerError, "API server error (#{response.status}): The server encountered an error"
      else
        raise APIError, "Unknown API error (#{response.status})"
      end
    end

    private

    def handle_client_error(response, error_type)
      error_body = begin
        JSON.parse(response.body)
      rescue StandardError
        { "error" => { "message" => response.body } }
      end

      message = error_body.dig("error", "message") || "Unknown error"
      raise ClientError, "#{error_type} (#{response.status}): #{message}"
    end
  end

  class ConnectionBuilder
    def initialize(config)
      @config = config
    end

    def build_connection
      Faraday.new(url: @config.api_base_url) do |faraday|
        faraday.options.timeout = @config.timeout
        faraday.options.open_timeout = 10
        faraday.adapter Faraday.default_adapter
        faraday.request :retry, max: @config.max_retries, interval: 0.5
      end
    end
  end

  # FIXED: Separate connection builder for streaming
  class StreamingConnectionBuilder
    def initialize(config)
      @config = config
    end

    def build_connection
      Faraday.new(url: @config.api_base_url) do |faraday|
        faraday.options.timeout = @config.timeout * 3 # Longer timeout for streaming
        faraday.options.open_timeout = 15
        faraday.adapter Faraday.default_adapter

        # No retry for streaming connections
        # Streaming should handle failures gracefully
      end
    end
  end

  class ContentExtractor
    def extract(response)
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
  end

  class CacheKeyGenerator
    def initialize(model)
      @model = model
    end

    def generate(text, system_instruction, options)
      key_parts = [
        @model,
        text,
        system_instruction,
        options.to_s
      ]

      Digest::SHA256.hexdigest(key_parts.join("--"))
    end
  end
end
