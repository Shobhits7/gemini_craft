# frozen_string_literal: true

require "spec_helper"

RSpec.describe GeminiCraft::Cache do
  let(:config) do
    instance_double(GeminiCraft::Configuration, cache_ttl: 3600)
  end
  let(:cache) { described_class.new(config) }

  describe "#get" do
    it "returns nil for non-existent keys" do
      expect(cache.get("non-existent-key")).to be_nil
    end

    it "returns the cached value for existing keys" do
      cache.set("test-key", "test-value")
      expect(cache.get("test-key")).to eq("test-value")
    end

    it "returns nil for expired keys" do
      cache.set("expired-key", "test-value")

      # Simulate expiration
      allow(Time).to receive(:now).and_return(Time.now + 3700)

      expect(cache.get("expired-key")).to be_nil
    end
  end

  describe "#set" do
    it "stores the value in the cache" do
      cache.set("new-key", "new-value")
      expect(cache.get("new-key")).to eq("new-value")
    end

    it "overwrites existing values" do
      cache.set("key", "original-value")
      cache.set("key", "updated-value")
      expect(cache.get("key")).to eq("updated-value")
    end
  end

  describe "#clear" do
    it "removes all entries from the cache" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")

      cache.clear

      expect(cache.get("key1")).to be_nil
      expect(cache.get("key2")).to be_nil
    end
  end

  describe "#cleanup" do
    it "removes only expired entries" do
      cache.set("fresh-key", "fresh-value")
      cache.set("expired-key", "expired-value")

      # Simulate partial expiration
      allow(cache.instance_variable_get(:@timestamps)).to receive(:[]).and_call_original
      allow(cache.instance_variable_get(:@timestamps)).to receive(:[]).with("expired-key").and_return(Time.now.to_i - 4000)

      cache.cleanup

      expect(cache.get("fresh-key")).to eq("fresh-value")
      expect(cache.get("expired-key")).to be_nil
    end
  end
end
