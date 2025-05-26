# frozen_string_literal: true

require "spec_helper"

RSpec.describe GeminiCraft::Cache do
  let(:config) do
    instance_double(
      GeminiCraft::Configuration,
      cache_ttl: 3600,
      cache_enabled: false
    )
  end
  let(:cache) { described_class.new(config) }

  after do
    cache.stop_cleanup_thread
  end

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
      allow(Time).to receive(:now).and_return(Time.now + 3700)
      expect(cache.get("expired-key")).to be_nil
    end

    it "updates access time when retrieving cached values" do
      cache.set("test-key", "test-value")
      initial_time = Time.now.to_i
      allow(Time).to receive(:now).and_return(Time.at(initial_time + 100))
      cache.get("test-key")
      expect(cache.instance_variable_get(:@access_times)["test-key"]).to eq(initial_time + 100)
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

    it "sets timestamps and access times" do
      current_time = Time.now.to_i
      allow(Time).to receive(:now).and_return(Time.at(current_time))
      cache.set("time-key", "time-value")
      timestamps = cache.instance_variable_get(:@timestamps)
      access_times = cache.instance_variable_get(:@access_times)
      expect(timestamps["time-key"]).to eq(current_time)
      expect(access_times["time-key"]).to eq(current_time)
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

    it "clears all internal storage" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")
      cache.clear
      store = cache.instance_variable_get(:@store)
      timestamps = cache.instance_variable_get(:@timestamps)
      access_times = cache.instance_variable_get(:@access_times)
      expect(store).to be_empty
      expect(timestamps).to be_empty
      expect(access_times).to be_empty
    end
  end

  describe "#stats" do
    it "returns cache statistics" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")
      stats = cache.stats
      expect(stats[:size]).to eq(2)
      expect(stats[:total_keys]).to contain_exactly("key1", "key2")
      expect(stats[:oldest_entry]).to be_a(Integer)
      expect(stats[:newest_entry]).to be_a(Integer)
    end

    it "returns empty stats for empty cache" do
      stats = cache.stats
      expect(stats[:size]).to eq(0)
      expect(stats[:total_keys]).to be_empty
      expect(stats[:oldest_entry]).to be_nil
      expect(stats[:newest_entry]).to be_nil
    end
  end

  describe "#cleanup" do
    it "removes only expired entries" do
      cache.set("fresh-key", "fresh-value")
      cache.set("expired-key", "expired-value")
      timestamps = cache.instance_variable_get(:@timestamps)
      timestamps["expired-key"] = Time.now.to_i - 4000
      expired_count = cache.cleanup
      expect(cache.get("fresh-key")).to eq("fresh-value")
      expect(cache.get("expired-key")).to be_nil
      expect(expired_count).to eq(1)
    end

    it "returns count of expired entries removed" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")
      cache.set("key3", "value3")
      timestamps = cache.instance_variable_get(:@timestamps)
      old_time = Time.now.to_i - 4000
      timestamps.each_key { |key| timestamps[key] = old_time }
      expired_count = cache.cleanup
      expect(expired_count).to eq(3)
      expect(cache.stats[:size]).to eq(0)
    end
  end

  describe "cleanup thread" do
    let(:config_with_cleanup) do
      instance_double(
        GeminiCraft::Configuration,
        cache_ttl: 1,
        cache_enabled: true
      )
    end

    it "starts cleanup thread when cache is enabled" do
      expect(Thread).to receive(:new).and_call_original
      cache_with_cleanup = described_class.new(config_with_cleanup)
      expect(cache_with_cleanup.instance_variable_get(:@cleanup_thread)).to be_a(Thread)
      cache_with_cleanup.stop_cleanup_thread
    end
  end
end
