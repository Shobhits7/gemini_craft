# frozen_string_literal: true

require "spec_helper"

RSpec.describe GeminiCraft::Client do
  let(:client) { described_class.new }
  let(:api_key) { "test-api-key" }
  let(:text) { "Hello there" }
  let(:system_instruction) { "You are a helpful assistant." }

  before do
    GeminiCraft.configure do |config|
      config.api_key = api_key
      config.model = "gemini-2.0-flash"
      config.cache_enabled = false
    end
  end

  describe "#generate_content" do
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
      stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}")
        .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
    end

    it "makes a request to the Gemini API" do
      result = client.generate_content(text)
      expect(result).to eq("I'm a helpful assistant. How can I help you today?")
    end

    it "includes system instructions when provided" do
      client.generate_content(text, system_instruction)

      expect(WebMock).to(have_requested(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}")
        .with do |req|
          body = JSON.parse(req.body)
          body.key?("system_instruction") &&
            body["system_instruction"]["parts"][0]["text"] == system_instruction
        end)
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
        # First request should hit the API
        first_result = client.generate_content(text, system_instruction)

        # Change the stub to return different response
        stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}")
          .to_return(status: 200, body: { candidates: [{ content: { parts: [{ text: "New response" }] } }] }.to_json)

        # Second request should use cache
        second_result = client.generate_content(text, system_instruction)

        expect(first_result).to eq(second_result)
        expect(WebMock).to have_requested(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}").once
      end
    end

    context "when API returns an error" do
      before do
        stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}")
          .to_return(status: 400, body: { error: { message: "Invalid request" } }.to_json)
      end

      it "raises an APIError" do
        expect { client.generate_content(text) }.to raise_error(GeminiCraft::APIError, /API client error/)
      end
    end
  end
end
