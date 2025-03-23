# frozen_string_literal: true

require "spec_helper"

RSpec.describe GeminiCraft do
  it "has a version number" do
    expect(GeminiCraft::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "yields configuration to the block" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.model = "test-model"
      end

      expect(described_class.configuration.api_key).to eq("test-key")
      expect(described_class.configuration.model).to eq("test-model")
    end
  end

  describe ".generate_content" do
    let(:client_instance) { instance_double(GeminiCraft::Client) }

    before do
      allow(GeminiCraft::Client).to receive(:new).and_return(client_instance)
      allow(client_instance).to receive(:generate_content).and_return("Generated content")
    end

    it "delegates to client.generate_content" do
      expect(described_class.generate_content("Hello", "System instruction", { option: "value" }))
        .to eq("Generated content")

      expect(client_instance).to have_received(:generate_content)
        .with("Hello", "System instruction", { option: "value" })
    end
  end
end
