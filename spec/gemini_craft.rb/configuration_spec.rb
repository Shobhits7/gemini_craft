# frozen_string_literal: true

# rubocop:disable RSpec/MultipleExpectations

require "spec_helper"

RSpec.describe GeminiCraft::Configuration do
  let(:configuration) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(configuration.api_base_url).to eq("https://generativelanguage.googleapis.com/v1beta")
      expect(configuration.model).to eq("gemini-2.0-flash")
      expect(configuration.timeout).to eq(30)
      expect(configuration.cache_enabled).to be(false)
      expect(configuration.cache_ttl).to eq(3600)
      expect(configuration.max_retries).to eq(3)
    end
  end

  describe "#validate!" do
    context "with missing API key" do
      it "raises ConfigurationError" do
        configuration.api_key = nil
        expect { configuration.validate! }.to raise_error(GeminiCraft::ConfigurationError, /API key/)
      end
    end

    context "with missing model" do
      it "raises ConfigurationError" do
        configuration.api_key = "test-key"
        configuration.model = nil
        expect { configuration.validate! }.to raise_error(GeminiCraft::ConfigurationError, /Model/)
      end
    end

    context "with valid configuration" do
      it "does not raise an error" do
        configuration.api_key = "test-key"
        expect { configuration.validate! }.not_to raise_error
      end
    end
  end
end

# rubocop:enable RSpec/MultipleExpectations
