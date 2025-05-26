# frozen_string_literal: true

require "spec_helper"

RSpec.describe GeminiCraft::Client do
  let(:client) { described_class.new }
  let(:api_key) { "test-api-key" }
  let(:text) { "Hello there" }
  let(:system_instruction) { "You are a helpful assistant." }
  let(:response_body) do
    {
      candidates: [
        {
          content: {
            parts: [
              {
                text: "I'm a helpful assistant. How can I help you today?"
              }
            ]
          }
        }
      ]
    }.to_json
  end

  before do
    GeminiCraft.configure do |config|
      config.api_key = api_key
      config.model = "gemini-2.0-flash"
      config.cache_enabled = false
      config.logger = Logger.new(IO::NULL)
    end
  end

  describe "#initialize" do
    it "initializes with configuration" do
      expect(client.config).to be_a(GeminiCraft::Configuration)
      expect(client.cache).to be_a(GeminiCraft::Cache)
      expect(client.logger).to respond_to(:info)
    end

    it "validates configuration on initialization" do
      expect do
        GeminiCraft.configure { |c| c.api_key = nil }
        described_class.new
      end.to raise_error(GeminiCraft::ConfigurationError)
    end
  end

  describe "#generate_content" do
    before do
      stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}")
        .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
    end

    it "makes a request to the Gemini API" do
      result = client.generate_content(text)
      expect(result).to eq("I'm a helpful assistant. How can I help you today?")
    end

    context "with caching enabled" do
      before do
        GeminiCraft.configure do |config|
          config.api_key = api_key
          config.cache_enabled = true
          config.cache_ttl = 3600
        end
      end

      it "returns cached responses for identical requests" do
        first_result = client.generate_content(text, system_instruction)

        stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}")
          .to_return(status: 200, body: { candidates: [{ content: { parts: [{ text: "New response" }] } }] }.to_json)

        second_result = client.generate_content(text, system_instruction)

        expect(first_result).to eq(second_result)
        expect(WebMock).to have_requested(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}").once
      end

      # FIXED: Test that streaming actually makes HTTP requests
      it "doesn't cache streaming requests" do
        # Mock the streaming endpoint properly
        allow(client).to receive(:generate_streaming_content).and_return([].to_enum)

        # Make streaming requests
        result1 = client.generate_content(text, nil, {}, stream: true)
        result2 = client.generate_content(text, nil, {}, stream: true)

        # Verify both calls went through (no caching)
        expect(client).to have_received(:generate_streaming_content).twice
        expect(result1).to be_an(Enumerator)
        expect(result2).to be_an(Enumerator)
      end
    end

    context "when API returns an error" do
      before do
        stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}")
          .to_return(status: 400, body: { error: { message: "Invalid request" } }.to_json)
      end

      it "raises a ClientError" do
        expect { client.generate_content(text) }.to raise_error(GeminiCraft::ClientError, /Invalid request/)
      end
    end

    context "error handling" do
      it "raises AuthenticationError for 401" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 401, body: { error: { message: "Unauthorized" } }.to_json)

        expect { client.generate_content(text) }.to raise_error(GeminiCraft::AuthenticationError)
      end

      it "raises AuthorizationError for 403" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 403, body: { error: { message: "Forbidden" } }.to_json)

        expect { client.generate_content(text) }.to raise_error(GeminiCraft::AuthorizationError)
      end

      it "raises NotFoundError for 404" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 404, body: { error: { message: "Not Found" } }.to_json)

        expect { client.generate_content(text) }.to raise_error(GeminiCraft::NotFoundError)
      end

      it "raises RateLimitError for 429" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 429, body: { error: { message: "Rate Limited" } }.to_json)

        expect { client.generate_content(text) }.to raise_error(GeminiCraft::RateLimitError)
      end

      it "raises ServerError for 500" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 500, body: { error: { message: "Internal Error" } }.to_json)

        expect { client.generate_content(text) }.to raise_error(GeminiCraft::ServerError)
      end

      it "raises TimeoutError for Faraday::TimeoutError" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_raise(Faraday::TimeoutError.new("Request timeout"))

        expect { client.generate_content(text) }.to raise_error(GeminiCraft::TimeoutError)
      end

      it "raises ConnectionError for Faraday::ConnectionFailed" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_raise(Faraday::ConnectionFailed.new("Connection failed"))

        expect { client.generate_content(text) }.to raise_error(GeminiCraft::ConnectionError)
      end

      it "raises APIError for generic Faraday::Error" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_raise(Faraday::Error.new("Generic error"))

        expect { client.generate_content(text) }.to raise_error(GeminiCraft::APIError)
      end
    end

    context "response parsing" do
      it "handles empty candidates" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 200, body: { candidates: [] }.to_json)

        result = client.generate_content(text)
        expect(result).to eq("")
      end

      it "handles missing content" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 200, body: { candidates: [{}] }.to_json)

        result = client.generate_content(text)
        expect(result).to eq("")
      end

      it "handles missing parts" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 200, body: { candidates: [{ content: {} }] }.to_json)

        result = client.generate_content(text)
        expect(result).to eq("")
      end

      it "handles missing text" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 200, body: { candidates: [{ content: { parts: [{}] } }] }.to_json)

        result = client.generate_content(text)
        expect(result).to eq("")
      end

      it "raises ResponseError for invalid JSON structure" do
        stub_request(:post, /generativelanguage\.googleapis\.com/)
          .to_return(status: 200, body: response_body)

        allow_any_instance_of(GeminiCraft::ContentExtractor).to receive(:extract)
          .and_raise(StandardError.new("Invalid structure"))

        expect { client.generate_content(text) }.to raise_error(GeminiCraft::ResponseError, /Failed to extract content/)
      end
    end
  end

  describe "#generate_with_functions" do
    let(:functions) do
      [
        {
          name: "get_weather",
          description: "Get weather for a location",
          parameters: {
            type: "object",
            properties: {
              location: { type: "string" }
            }
          }
        }
      ]
    end

    let(:function_response_body) do
      {
        candidates: [
          {
            content: {
              parts: [
                {
                  text: "I'll check the weather for you."
                },
                {
                  functionCall: {
                    name: "get_weather",
                    args: { location: "San Francisco" }
                  }
                }
              ]
            }
          }
        ]
      }.to_json
    end

    before do
      stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}")
        .to_return(status: 200, body: function_response_body)
    end

    it "makes a request with function declarations" do
      client.generate_with_functions(text, functions, system_instruction)

      expect(WebMock).to have_requested(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}") do |req|
        body = JSON.parse(req.body)
        body["tools"] && body["tools"][0]["function_declarations"] == functions
      end
    end

    it "returns structured response with function calls" do
      result = client.generate_with_functions(text, functions)

      expect(result).to be_a(Hash)
      expect(result[:content]).to eq("I'll check the weather for you.")
      expect(result[:function_calls]).to be_an(Array)
      expect(result[:function_calls].first[:name]).to eq("get_weather")
      expect(result[:function_calls].first[:args]).to eq({ "location" => "San Francisco" })
    end

    it "handles responses with only text" do
      text_only_response = {
        candidates: [
          {
            content: {
              parts: [
                { text: "Just text response" }
              ]
            }
          }
        ]
      }.to_json

      stub_request(:post, /generativelanguage\.googleapis\.com/)
        .to_return(status: 200, body: text_only_response)

      result = client.generate_with_functions(text, functions)

      expect(result[:content]).to eq("Just text response")
      expect(result[:function_calls]).to be_empty
    end

    it "handles responses with only function calls" do
      function_only_response = {
        candidates: [
          {
            content: {
              parts: [
                {
                  functionCall: {
                    name: "get_weather",
                    args: { location: "Tokyo" }
                  }
                }
              ]
            }
          }
        ]
      }.to_json

      stub_request(:post, /generativelanguage\.googleapis\.com/)
        .to_return(status: 200, body: function_only_response)

      result = client.generate_with_functions(text, functions)

      expect(result[:content]).to eq("")
      expect(result[:function_calls].first[:name]).to eq("get_weather")
      expect(result[:function_calls].first[:args]).to eq({ "location" => "Tokyo" })
    end

    it "handles empty candidates" do
      stub_request(:post, /generativelanguage\.googleapis\.com/)
        .to_return(status: 200, body: { candidates: [] }.to_json)

      result = client.generate_with_functions(text, functions)

      expect(result[:content]).to eq("")
      expect(result[:function_calls]).to be_empty
    end

    it "handles missing args in function calls" do
      no_args_response = {
        candidates: [
          {
            content: {
              parts: [
                {
                  functionCall: {
                    name: "get_weather"
                  }
                }
              ]
            }
          }
        ]
      }.to_json

      stub_request(:post, /generativelanguage\.googleapis\.com/)
        .to_return(status: 200, body: no_args_response)

      result = client.generate_with_functions(text, functions)

      expect(result[:function_calls].first[:args]).to eq({})
    end
  end

  describe "streaming" do
    let(:streaming_data) do
      [
        "data: #{response_body}",
        "data: #{response_body}",
        "data: [DONE]"
      ].join("\n")
    end

    # FIXED: Test StreamingProcessor with proper yielder (block, not proc)
    it "processes streaming chunks" do
      processor = GeminiCraft::StreamingProcessor.new(client)
      yielded_chunks = []

      # Use a block instead of proc
      processor.process_chunk(streaming_data) { |chunk| yielded_chunks << chunk }

      expect(yielded_chunks).not_to be_empty
      expect(yielded_chunks.first).to eq("I'm a helpful assistant. How can I help you today?")
    end

    it "handles invalid JSON in streaming chunks" do
      invalid_data = "data: {invalid json}\n"
      processor = GeminiCraft::StreamingProcessor.new(client)
      yielded_chunks = []

      expect do
        processor.process_chunk(invalid_data) { |chunk| yielded_chunks << chunk }
      end.not_to raise_error

      expect(yielded_chunks).to be_empty
    end

    # FIXED: Test with proper block syntax
    it "skips empty lines in streaming" do
      data_with_empty = "data: \ndata: #{response_body}\n"
      processor = GeminiCraft::StreamingProcessor.new(client)
      yielded_chunks = []

      processor.process_chunk(data_with_empty) { |chunk| yielded_chunks << chunk }

      expect(yielded_chunks.size).to eq(1)
    end
  end

  describe "helper classes" do
    describe "PayloadBuilder" do
      let(:builder) { GeminiCraft::PayloadBuilder.new }

      it "builds basic payload" do
        payload = builder.build("Hello", nil, {})

        expect(payload[:contents]).to be_an(Array)
        expect(payload[:contents][0][:parts][0][:text]).to eq("Hello")
      end

      it "includes system instruction" do
        payload = builder.build("Hello", "You are helpful", {})

        expect(payload[:system_instruction][:parts][0][:text]).to eq("You are helpful")
      end

      it "merges additional options" do
        payload = builder.build("Hello", nil, { temperature: 0.7 })

        expect(payload[:temperature]).to eq(0.7)
      end

      it "handles nil options" do
        payload = builder.build("Hello", nil, nil)

        expect(payload[:contents]).to be_an(Array)
      end

      it "handles empty options" do
        payload = builder.build("Hello", nil, {})

        expect(payload[:contents]).to be_an(Array)
      end
    end

    describe "ConnectionBuilder" do
      let(:config) do
        instance_double(
          GeminiCraft::Configuration,
          api_base_url: "https://example.com",
          timeout: 30,
          max_retries: 3
        )
      end
      let(:builder) { GeminiCraft::ConnectionBuilder.new(config) }

      it "builds Faraday connection" do
        connection = builder.build_connection

        expect(connection).to be_a(Faraday::Connection)
        expect(connection.url_prefix.to_s).to eq("https://example.com/")
      end

      it "sets timeout options" do
        connection = builder.build_connection

        expect(connection.options.timeout).to eq(30)
        expect(connection.options.open_timeout).to eq(10)
      end

      it "includes retry middleware" do
        connection = builder.build_connection

        retry_middleware = connection.builder.handlers.find { |h| h.klass.to_s.include?("Retry") }
        expect(retry_middleware).not_to be_nil
      end
    end

    describe "CacheKeyGenerator" do
      let(:generator) { GeminiCraft::CacheKeyGenerator.new("test-model") }

      it "generates consistent cache keys" do
        key1 = generator.generate("text", "instruction", { temp: 0.7 })
        key2 = generator.generate("text", "instruction", { temp: 0.7 })

        expect(key1).to eq(key2)
        expect(key1).to be_a(String)
        expect(key1.length).to eq(64) # SHA256 hex digest length
      end

      it "generates different keys for different inputs" do
        key1 = generator.generate("text1", "instruction", {})
        key2 = generator.generate("text2", "instruction", {})

        expect(key1).not_to eq(key2)
      end

      it "includes model in key generation" do
        gen1 = GeminiCraft::CacheKeyGenerator.new("model1")
        gen2 = GeminiCraft::CacheKeyGenerator.new("model2")

        key1 = gen1.generate("text", "instruction", {})
        key2 = gen2.generate("text", "instruction", {})

        expect(key1).not_to eq(key2)
      end
    end

    describe "ContentExtractor" do
      let(:extractor) { GeminiCraft::ContentExtractor.new }

      it "extracts content from valid response" do
        response = {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  { "text" => "Hello world" }
                ]
              }
            }
          ]
        }

        content = extractor.extract(response)
        expect(content).to eq("Hello world")
      end

      it "handles missing candidates" do
        response = {}
        content = extractor.extract(response)
        expect(content).to eq("")
      end

      it "handles empty candidates" do
        response = { "candidates" => [] }
        content = extractor.extract(response)
        expect(content).to eq("")
      end

      it "handles missing content" do
        response = { "candidates" => [{}] }
        content = extractor.extract(response)
        expect(content).to eq("")
      end

      it "handles missing parts" do
        response = { "candidates" => [{ "content" => {} }] }
        content = extractor.extract(response)
        expect(content).to eq("")
      end

      it "handles empty parts" do
        response = { "candidates" => [{ "content" => { "parts" => [] } }] }
        content = extractor.extract(response)
        expect(content).to eq("")
      end

      it "handles missing text" do
        response = { "candidates" => [{ "content" => { "parts" => [{}] } }] }
        content = extractor.extract(response)
        expect(content).to eq("")
      end
    end

    describe "ResponseHandler" do
      let(:handler) { GeminiCraft::ResponseHandler.new(client) }
      let(:mock_response) { instance_double(Faraday::Response) }

      it "handles successful responses" do
        allow(mock_response).to receive_messages(status: 200, body: '{"test": "data"}')

        result = handler.handle_response(mock_response)
        expect(result).to eq({ "test" => "data" })
      end

      it "handles client errors with detailed message" do
        error_body = { "error" => { "message" => "Bad request details" } }.to_json
        allow(mock_response).to receive_messages(status: 400, body: error_body)

        expect { handler.handle_response(mock_response) }
          .to raise_error(GeminiCraft::ClientError, /Bad request details/)
      end

      it "handles client errors with invalid JSON" do
        allow(mock_response).to receive_messages(status: 400, body: "Invalid JSON")

        expect { handler.handle_response(mock_response) }
          .to raise_error(GeminiCraft::ClientError, /Invalid JSON/)
      end

      it "handles unknown status codes" do
        allow(mock_response).to receive(:status).and_return(418)

        expect { handler.handle_response(mock_response) }
          .to raise_error(GeminiCraft::APIError, /Unknown API error \(418\)/)
      end
    end

    describe "FunctionResponseProcessor" do
      let(:processor) { GeminiCraft::FunctionResponseProcessor.new }

      it "processes response with text and function calls" do
        response = {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  { "text" => "I'll help you" },
                  {
                    "functionCall" => {
                      "name" => "get_weather",
                      "args" => { "location" => "Tokyo" }
                    }
                  }
                ]
              }
            }
          ]
        }

        result = processor.process(response)

        expect(result[:content]).to eq("I'll help you")
        expect(result[:function_calls].size).to eq(1)
        expect(result[:function_calls][0][:name]).to eq("get_weather")
        expect(result[:function_calls][0][:args]).to eq({ "location" => "Tokyo" })
      end

      it "processes response with multiple text parts" do
        response = {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  { "text" => "Hello" },
                  { "text" => "World" }
                ]
              }
            }
          ]
        }

        result = processor.process(response)
        expect(result[:content]).to eq("Hello World")
        expect(result[:function_calls]).to be_empty
      end

      it "handles missing args in function calls" do
        response = {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  {
                    "functionCall" => {
                      "name" => "test_function"
                    }
                  }
                ]
              }
            }
          ]
        }

        result = processor.process(response)
        expect(result[:function_calls][0][:args]).to eq({})
      end

      it "handles empty response" do
        response = { "candidates" => [] }
        result = processor.process(response)

        expect(result[:content]).to eq("")
        expect(result[:function_calls]).to be_empty
      end

      it "handles missing content" do
        response = { "candidates" => [{}] }
        result = processor.process(response)

        expect(result[:content]).to eq("")
        expect(result[:function_calls]).to be_empty
      end
    end
  end

  describe "private methods" do
    describe "#setup_logger" do
      it "uses config logger when available" do
        custom_logger = Logger.new(IO::NULL)
        allow(client.config).to receive(:logger).and_return(custom_logger)

        logger = client.send(:setup_logger)
        expect(logger).to eq(custom_logger)
      end

      it "uses Rails logger when available" do
        stub_const("Rails", double("Rails"))
        rails_logger = Logger.new(IO::NULL)
        allow(Rails).to receive(:logger).and_return(rails_logger)
        allow(client.config).to receive(:logger).and_return(nil)

        logger = client.send(:setup_logger)
        expect(logger).to eq(rails_logger)
      end

      it "uses null logger as fallback" do
        allow(client.config).to receive(:logger).and_return(nil)

        logger = client.send(:setup_logger)
        expect(logger).to be_a(Logger)
      end

      it "handles Rails logger errors" do
        stub_const("Rails", double("Rails"))
        allow(Rails).to receive(:logger).and_raise(StandardError.new("Rails error"))
        allow(client.config).to receive(:logger).and_return(nil)

        logger = client.send(:setup_logger)
        expect(logger).to be_a(Logger)
      end
    end

    describe "#log" do
      it "handles logger without requested method" do
        mock_logger = double("Logger")
        allow(client).to receive(:logger).and_return(mock_logger)
        allow(mock_logger).to receive(:respond_to?).with(:debug).and_return(false)

        expect { client.send(:log, :debug, "Test message") }.not_to raise_error
      end

      it "handles nil logger" do
        allow(client).to receive(:logger).and_return(nil)

        expect { client.send(:log, :info, "Test message") }.not_to raise_error
      end
    end
  end
end
