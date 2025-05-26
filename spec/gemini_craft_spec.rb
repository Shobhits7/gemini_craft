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

    it "allows chaining configuration calls" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.model = "test-model"
        config.cache_enabled = true
        config.timeout = 45
      end

      config = described_class.configuration
      expect(config.api_key).to eq("test-key")
      expect(config.model).to eq("test-model")
      expect(config.cache_enabled).to be(true)
      expect(config.timeout).to eq(45)
    end
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(GeminiCraft::Configuration)
    end

    it "returns the same instance on multiple calls" do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to eq(config2)
    end
  end

  describe ".client" do
    it "returns a Client instance" do
      described_class.configure { |c| c.api_key = "test-key" }
      expect(described_class.client).to be_a(GeminiCraft::Client)
    end

    it "creates a new client instance each time" do
      described_class.configure { |c| c.api_key = "test-key" }
      client1 = described_class.client
      client2 = described_class.client
      expect(client1).not_to eq(client2)
    end
  end

  describe ".generate_content" do
    let(:client_instance) { instance_double(GeminiCraft::Client) }

    before do
      allow(GeminiCraft::Client).to receive(:new).and_return(client_instance)
      allow(client_instance).to receive(:generate_content).and_return("Generated content")
    end

    # FIXED: Include the stream keyword argument in expectation
    it "delegates to client.generate_content" do
      expect(described_class.generate_content("Hello", "System instruction", { option: "value" }))
        .to eq("Generated content")

      expect(client_instance).to have_received(:generate_content)
        .with("Hello", "System instruction", { option: "value" }, stream: false)
    end

    it "passes stream parameter correctly" do
      described_class.generate_content("Hello", nil, {}, stream: true)

      expect(client_instance).to have_received(:generate_content)
        .with("Hello", nil, {}, stream: true)
    end

    it "handles all parameter combinations" do
      described_class.generate_content("Hello")

      expect(client_instance).to have_received(:generate_content)
        .with("Hello", nil, {}, stream: false)
    end
  end

  describe ".generate_with_functions" do
    let(:client_instance) { instance_double(GeminiCraft::Client) }
    let(:functions) { [{ name: "test_function" }] }

    before do
      allow(GeminiCraft::Client).to receive(:new).and_return(client_instance)
      allow(client_instance).to receive(:generate_with_functions)
        .and_return({ content: "Generated", function_calls: [] })
    end

    it "delegates to client.generate_with_functions" do
      result = described_class.generate_with_functions("Hello", functions, "System", { temp: 0.7 })

      expect(result).to eq({ content: "Generated", function_calls: [] })
      expect(client_instance).to have_received(:generate_with_functions)
        .with("Hello", functions, "System", { temp: 0.7 })
    end

    it "handles minimal parameters" do
      described_class.generate_with_functions("Hello", functions)

      expect(client_instance).to have_received(:generate_with_functions)
        .with("Hello", functions, nil, {})
    end
  end

  describe ".stream_content" do
    let(:client_instance) { instance_double(GeminiCraft::Client) }

    before do
      allow(described_class).to receive(:generate_content).and_return("streamed")
    end

    it "calls generate_content with stream: true" do
      described_class.stream_content("Hello", "System", { temp: 0.7 })

      expect(described_class).to have_received(:generate_content)
        .with("Hello", "System", { temp: 0.7 }, stream: true)
    end

    it "handles minimal parameters" do
      described_class.stream_content("Hello")

      expect(described_class).to have_received(:generate_content)
        .with("Hello", nil, {}, stream: true)
    end
  end

  describe ".cache_stats" do
    let(:client_instance) { instance_double(GeminiCraft::Client) }
    let(:cache_instance) { instance_double(GeminiCraft::Cache) }

    before do
      allow(GeminiCraft::Client).to receive(:new).and_return(client_instance)
      allow(client_instance).to receive(:cache).and_return(cache_instance)
      allow(cache_instance).to receive(:stats).and_return({ size: 5 })
    end

    it "returns cache statistics" do
      stats = described_class.cache_stats

      expect(stats).to eq({ size: 5 })
      expect(cache_instance).to have_received(:stats)
    end
  end

  describe ".clear_cache" do
    let(:client_instance) { instance_double(GeminiCraft::Client) }
    let(:cache_instance) { instance_double(GeminiCraft::Cache) }

    before do
      allow(GeminiCraft::Client).to receive(:new).and_return(client_instance)
      allow(client_instance).to receive(:cache).and_return(cache_instance)
      allow(cache_instance).to receive(:clear)
    end

    it "clears the cache" do
      described_class.clear_cache

      expect(cache_instance).to have_received(:clear)
    end
  end

  describe ".reset_configuration" do
    it "resets configuration to defaults" do
      described_class.configure { |c| c.api_key = "test-key" }
      expect(described_class.configuration.api_key).to eq("test-key")

      described_class.reset_configuration

      expect(described_class.configuration.api_key).to be_nil
    end

    it "creates a new configuration instance" do
      old_config = described_class.configuration
      described_class.reset_configuration
      new_config = described_class.configuration

      expect(new_config).not_to eq(old_config)
    end
  end
end
