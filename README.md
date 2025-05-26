# GeminiCraft 🚀

[![Gem Version](https://badge.fury.io/rb/gemini_craft.svg)](https://badge.fury.io/rb/gemini_craft)
[![Ruby](https://github.com/shobhits7/gemini_craft/workflows/Ruby/badge.svg)](https://github.com/shobhits7/gemini_craft/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful Ruby gem for generating content using Google's Gemini AI with advanced features like streaming, function calling, intelligent caching, and Rails integration.

## ✨ Features

- 🤖 **Simple Content Generation** - Easy-to-use interface for Gemini AI
- 🌊 **Streaming Support** - Real-time content generation for better UX
- 🔧 **Function Calling** - Enable AI to call your Ruby functions/APIs
- 🚀 **Enhanced Caching** - Intelligent caching with automatic cleanup
- 📊 **Comprehensive Error Handling** - Specific error types for better debugging
- 📝 **Rails Integration** - Built-in Rails logger support
- ⚡ **Connection Pooling** - Optimized for high-throughput applications
- 🔄 **Automatic Retries** - Smart retry logic for failed requests
- 🛡️ **Thread Safe** - Safe for concurrent usage

## 📦 Installation

Add this line to your application's Gemfile:

```ruby
gem 'gemini_craft'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install gemini_craft
```

## 🔑 Getting Started

### 1. Get Your API Key

Get your Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey).

### 2. Basic Configuration

```ruby
require 'gemini_craft'

GeminiCraft.configure do |config|
  config.api_key = 'your-gemini-api-key'
  # Or set the GEMINI_API_KEY environment variable
end
```

### 3. Generate Your First Content

```ruby
response = GeminiCraft.generate_content("Write a haiku about Ruby programming")
puts response
```

## 🔧 Configuration

### Basic Configuration

```ruby
GeminiCraft.configure do |config|
  config.api_key = 'your-gemini-api-key'
  config.model = 'gemini-2.0-flash'     # Default model
  config.timeout = 30                   # Request timeout in seconds
  config.max_retries = 3               # Number of retry attempts
end
```

### Advanced Configuration

```ruby
GeminiCraft.configure do |config|
  # Authentication
  config.api_key = 'your-gemini-api-key'
  
  # Model Configuration
  config.model = 'gemini-2.0-flash'
  config.api_base_url = 'https://generativelanguage.googleapis.com/v1beta'
  
  # Performance & Reliability
  config.timeout = 45
  config.max_retries = 5
  config.connection_pool_size = 10
  config.keep_alive_timeout = 60
  
  # Caching
  config.cache_enabled = true
  config.cache_ttl = 3600  # 1 hour
  
  # Logging (Rails integration)
  config.logger = Rails.logger
  config.log_level = :info
  
  # Features
  config.streaming_enabled = true
end
```

### Environment Variables

```bash
# Set your API key
export GEMINI_API_KEY="your-api-key-here"
```

## 🚀 Usage Examples

### Basic Content Generation

```ruby
# Simple text generation
response = GeminiCraft.generate_content("Explain quantum computing in simple terms")
puts response

# With system instruction
system_instruction = "You are a helpful coding assistant. Be concise and practical."
response = GeminiCraft.generate_content(
  "How do I sort an array in Ruby?", 
  system_instruction
)
puts response

# With custom options
options = {
  temperature: 0.7,      # Creativity level (0.0 - 1.0)
  topK: 40,             # Consider top K tokens
  topP: 0.95,           # Nucleus sampling
  maxOutputTokens: 1024  # Maximum response length
}

response = GeminiCraft.generate_content(
  "Write a creative story about AI",
  "You are a creative writer",
  options
)
puts response
```

### 🌊 Streaming Content

Perfect for real-time applications like chatbots or live content generation:

```ruby
# Method 1: Using stream_content
puts "Generating story (streaming):"
stream = GeminiCraft.stream_content("Tell me an adventure story")

stream.each do |chunk|
  print chunk
  $stdout.flush
  sleep(0.02) # Optional: Add slight delay for visual effect
end
puts "\n"

# Method 2: Using generate_content with stream option
GeminiCraft.generate_content(
  "Explain machine learning", 
  stream: true
).each do |chunk|
  print chunk
  $stdout.flush
end

# Method 3: Collect all chunks
chunks = []
GeminiCraft.stream_content("Write a poem").each { |chunk| chunks << chunk }
full_response = chunks.join
puts full_response
```

### 🔧 Function Calling

Enable AI to call your Ruby functions/APIs:

```ruby
# Define available functions
functions = [
  {
    name: "get_current_weather",
    description: "Get the current weather in a given location",
    parameters: {
      type: "object",
      properties: {
        location: {
          type: "string",
          description: "The city and state, e.g. San Francisco, CA"
        },
        unit: {
          type: "string",
          enum: ["celsius", "fahrenheit"],
          description: "Temperature unit"
        }
      },
      required: ["location"]
    }
  },
  {
    name: "calculate_tip",
    description: "Calculate tip amount for a bill",
    parameters: {
      type: "object",
      properties: {
        bill_amount: {
          type: "number",
          description: "The total bill amount"
        },
        tip_percentage: {
          type: "number",
          description: "Tip percentage (default: 18)"
        }
      },
      required: ["bill_amount"]
    }
  }
]

# Generate content with function calling
result = GeminiCraft.generate_with_functions(
  "What's the weather like in Tokyo? Also calculate 18% tip for a $50 bill.",
  functions,
  "You are a helpful assistant that can check weather and calculate tips."
)

puts "AI Response: #{result[:content]}"

# Handle function calls
result[:function_calls].each do |call|
  case call[:name]
  when "get_current_weather"
    location = call[:args]["location"]
    unit = call[:args]["unit"] || "celsius"
    # Call your weather API here
    puts "🌤️  Would call weather API for #{location} in #{unit}"
    
  when "calculate_tip"
    bill = call[:args]["bill_amount"]
    tip_pct = call[:args]["tip_percentage"] || 18
    tip = (bill * tip_pct / 100).round(2)
    puts "💰 Tip calculation: $#{bill} * #{tip_pct}% = $#{tip}"
  end
end
```

### 🔄 Using the Client Directly

For more control over the client instance:

```ruby
client = GeminiCraft.client

# Standard generation
response = client.generate_content("Hello, how are you?")
puts response

# With system instruction and options
response = client.generate_content(
  "Explain Ruby blocks",
  "You are a Ruby expert who teaches with examples",
  { temperature: 0.3, maxOutputTokens: 500 }
)
puts response

# Function calling with client
result = client.generate_with_functions(
  "What's 15% tip on $80?",
  [tip_function],
  "You are a helpful calculator"
)
```

### 📊 Cache Management

Intelligent caching for improved performance:

```ruby
# Enable caching in configuration
GeminiCraft.configure do |config|
  config.cache_enabled = true
  config.cache_ttl = 1800  # 30 minutes
end

# Same requests will be cached
response1 = GeminiCraft.generate_content("What is Ruby?")
response2 = GeminiCraft.generate_content("What is Ruby?") # Served from cache

# Check cache statistics
stats = GeminiCraft.cache_stats
puts "Cache entries: #{stats[:size]}"
puts "Oldest entry: #{Time.at(stats[:oldest_entry]) if stats[:oldest_entry]}"
puts "Newest entry: #{Time.at(stats[:newest_entry]) if stats[:newest_entry]}"

# Clear cache manually
GeminiCraft.clear_cache
puts "Cache cleared!"
```

### 🛡️ Error Handling

Comprehensive error handling with specific error types:

```ruby
begin
  response = GeminiCraft.generate_content("Hello there!")
  puts response
rescue GeminiCraft::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "Please check your API key"
rescue GeminiCraft::RateLimitError => e
  puts "⏰ Rate limit exceeded: #{e.message}"
  puts "Please wait before making more requests"
rescue GeminiCraft::TimeoutError => e
  puts "⏱️  Request timed out: #{e.message}"
  puts "Try increasing the timeout or check your connection"
rescue GeminiCraft::ConnectionError => e
  puts "🌐 Connection failed: #{e.message}"
  puts "Please check your internet connection"
rescue GeminiCraft::ServerError => e
  puts "🔧 Server error: #{e.message}"
  puts "The API service may be temporarily unavailable"
rescue GeminiCraft::APIError => e
  puts "🚨 API error: #{e.message}"
rescue StandardError => e
  puts "💥 Unexpected error: #{e.message}"
end
```

### 🔧 Rails Integration

Perfect integration with Ruby on Rails applications:

```ruby
# config/initializers/gemini_craft.rb
GeminiCraft.configure do |config|
  config.api_key = Rails.application.credentials.gemini_api_key
  config.logger = Rails.logger
  config.log_level = Rails.env.production? ? :warn : :info
  config.cache_enabled = Rails.env.production?
  config.cache_ttl = 30.minutes
  config.timeout = 45
  config.max_retries = 5
end

# In your controllers
class ContentController < ApplicationController
  def generate
    begin
      @content = GeminiCraft.generate_content(
        params[:prompt],
        "You are a helpful assistant for #{current_user.name}",
        { temperature: 0.7 }
      )
      render json: { content: @content }
    rescue GeminiCraft::RateLimitError
      render json: { error: "Rate limit exceeded" }, status: 429
    rescue GeminiCraft::APIError => e
      Rails.logger.error "Gemini API error: #{e.message}"
      render json: { error: "Content generation failed" }, status: 500
    end
  end

  def stream_generate
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    
    begin
      GeminiCraft.stream_content(params[:prompt]).each do |chunk|
        response.stream.write("data: #{chunk}\n\n")
      end
    ensure
      response.stream.close
    end
  end
end

# In your models
class Article < ApplicationRecord
  def generate_summary
    return if content.blank?
    
    self.summary = GeminiCraft.generate_content(
      "Summarize this article in 2-3 sentences: #{content}",
      "You are a professional editor creating concise summaries"
    )
  end
end

# Background jobs
class ContentGenerationJob < ApplicationJob
  def perform(user_id, prompt)
    user = User.find(user_id)
    
    content = GeminiCraft.generate_content(
      prompt,
      "Generate content for #{user.name}",
      { temperature: 0.8, maxOutputTokens: 2000 }
    )
    
    user.generated_contents.create!(prompt: prompt, content: content)
  rescue GeminiCraft::APIError => e
    Rails.logger.error "Content generation failed for user #{user_id}: #{e.message}"
    # Handle error (retry, notify user, etc.)
  end
end
```

## ⚙️ Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `api_key` | `ENV['GEMINI_API_KEY']` | Your Gemini API key |
| `model` | `'gemini-2.0-flash'` | The Gemini model to use |
| `api_base_url` | `'https://generativelanguage.googleapis.com/v1beta'` | Base URL for the API |
| `timeout` | `30` | Request timeout in seconds |
| `cache_enabled` | `false` | Enable response caching |
| `cache_ttl` | `3600` | Cache time-to-live in seconds |
| `max_retries` | `3` | Number of retry attempts |
| `logger` | `nil` | Logger instance for debugging |
| `log_level` | `:info` | Logging level (`:debug`, `:info`, `:warn`, `:error`, `:fatal`) |
| `streaming_enabled` | `false` | Enable streaming support |
| `connection_pool_size` | `5` | HTTP connection pool size |
| `keep_alive_timeout` | `30` | Keep-alive timeout for connections |

## 🏗️ Available Models

| Model | Description | Best For |
|-------|-------------|----------|
| `gemini-2.0-flash` | Fast, efficient model | General content generation, chatbots |
| `gemini-1.5-pro` | Most capable model | Complex reasoning, analysis |
| `gemini-1.5-flash` | Balanced speed and capability | Most applications |

## 🚨 Error Types

The gem provides specific error types for better error handling:

- `GeminiCraft::Error` - Base error class
- `GeminiCraft::APIError` - General API errors
- `GeminiCraft::AuthenticationError` - Invalid API key or authentication failures
- `GeminiCraft::AuthorizationError` - Access forbidden or permission issues
- `GeminiCraft::NotFoundError` - Model or endpoint not found
- `GeminiCraft::RateLimitError` - Rate limit exceeded
- `GeminiCraft::ClientError` - Client-side errors (4xx)
- `GeminiCraft::ServerError` - Server-side errors (5xx)
- `GeminiCraft::TimeoutError` - Request timeouts
- `GeminiCraft::ConnectionError` - Connection failures
- `GeminiCraft::StreamingError` - Streaming-specific errors
- `GeminiCraft::ResponseError` - Response parsing errors
- `GeminiCraft::ConfigurationError` - Configuration errors

## 🎯 Best Practices

### 1. API Key Security
```ruby
# ✅ Good: Use environment variables
config.api_key = ENV['GEMINI_API_KEY']

# ✅ Good: Use Rails credentials
config.api_key = Rails.application.credentials.gemini_api_key

# ❌ Bad: Hard-code in source
config.api_key = "your-actual-api-key"
```

### 2. Error Handling
```ruby
# ✅ Good: Specific error handling
rescue GeminiCraft::RateLimitError
  # Implement backoff strategy
rescue GeminiCraft::AuthenticationError
  # Log and alert about API key issues

# ❌ Bad: Generic error handling
rescue StandardError
  # Too broad, might hide important errors
```

### 3. Caching Strategy
```ruby
# ✅ Good: Enable caching for production
GeminiCraft.configure do |config|
  config.cache_enabled = Rails.env.production?
  config.cache_ttl = 1.hour
end

# ✅ Good: Cache expensive operations
def generate_analysis(data)
  cache_key = "analysis_#{Digest::SHA256.hexdigest(data)}"
  Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
    GeminiCraft.generate_content("Analyze: #{data}")
  end
end
```

### 4. Streaming for Better UX
```ruby
# ✅ Good: Use streaming for long content
def stream_story
  GeminiCraft.stream_content("Write a long story").each do |chunk|
    ActionCable.server.broadcast("story_channel", { chunk: chunk })
  end
end
```

### 5. Function Calling
```ruby
# ✅ Good: Validate function parameters
def execute_function_call(call)
  case call[:name]
  when "get_weather"
    location = call[:args]["location"]
    return "Location required" if location.blank?
    
    WeatherService.new.get_weather(location)
  end
end
```

## 🧪 Testing

### RSpec Integration

```ruby
# spec/support/gemini_craft.rb
RSpec.configure do |config|
  config.before(:suite) do
    GeminiCraft.configure do |config|
      config.api_key = "test-api-key"
      config.cache_enabled = false
      config.logger = Logger.new(IO::NULL)
    end
  end
end

# In your specs
RSpec.describe ContentGenerator do
  before do
    allow(GeminiCraft).to receive(:generate_content)
      .and_return("Generated content")
  end

  it "generates content" do
    result = subject.generate_summary("test input")
    expect(result).to eq("Generated content")
  end
end
```

### WebMock for Testing

```ruby
# Gemfile (test group)
gem 'webmock'

# In your test
require 'webmock/rspec'

RSpec.describe "Gemini integration" do
  before do
    stub_request(:post, /generativelanguage\.googleapis\.com/)
      .to_return(
        status: 200,
        body: {
          candidates: [{
            content: {
              parts: [{ text: "Test response" }]
            }
          }]
        }.to_json
      )
  end

  it "generates content" do
    result = GeminiCraft.generate_content("test")
    expect(result).to eq("Test response")
  end
end
```

## 🔄 Migration from v0.1.x

The v0.2.0 release maintains backward compatibility. However, to use new features:

```ruby
# Old way (still works)
response = GeminiCraft.generate_content("Hello")

# New way with streaming
stream = GeminiCraft.stream_content("Hello")

# New way with function calling
result = GeminiCraft.generate_with_functions("Hello", functions)

# Enhanced error handling
rescue GeminiCraft::RateLimitError # New specific error type
```

## 🚀 Performance Tips

1. **Enable Caching**: For production applications to reduce API calls
2. **Use Streaming**: For better user experience with long responses  
3. **Implement Proper Retry Logic**: Handle transient failures gracefully
4. **Monitor Rate Limits**: Implement backoff strategies for sustained usage
5. **Optimize Prompts**: Shorter, clearer prompts often work better
6. **Batch Operations**: Group related requests when possible

## 📋 Troubleshooting

### Common Issues

**Authentication Error**
```ruby
# Check your API key
puts ENV['GEMINI_API_KEY'] # Should not be nil
```

**Rate Limiting**
```ruby
# Implement exponential backoff
rescue GeminiCraft::RateLimitError
  sleep(2 ** retry_count)
  retry if (retry_count += 1) < 3
```

**Timeout Issues**
```ruby
# Increase timeout for complex requests
GeminiCraft.configure { |c| c.timeout = 120 }
```

**Caching Problems**
```ruby
# Clear cache if responses seem stale
GeminiCraft.clear_cache
```

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for your changes
5. Ensure all tests pass (`bundle exec rake spec`)
6. Ensure code style is correct (`bundle exec rake rubocop`)
7. Commit your changes (`git commit -am 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Create a Pull Request

### Development Setup

```bash
git clone https://github.com/shobhits7/gemini_craft.git
cd gemini_craft
bin/setup
bundle exec rake spec
```

### Running Tests

```bash
# Run all tests
bundle exec rake spec

# Run specific test file
bundle exec rspec spec/gemini_craft/client_spec.rb

# Run with coverage
COVERAGE=true bundle exec rake spec
```

### Code Style

```bash
# Check code style
bundle exec rake rubocop

# Auto-fix issues
bundle exec rubocop -a
```

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 🏆 Code of Conduct

Everyone interacting in the GeminiCraft project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/shobhits7/gemini_craft/blob/main/CODE_OF_CONDUCT.md).

## 🔗 Links

- [GitHub Repository](https://github.com/shobhits7/gemini_craft)
- [RubyGems Page](https://rubygems.org/gems/gemini_craft)
- [Documentation](https://rubydoc.info/gems/gemini_craft)
- [Issues & Bug Reports](https://github.com/shobhits7/gemini_craft/issues)
- [Google AI Studio](https://makersuite.google.com/app/apikey) (Get API Key)
- [Gemini API Documentation](https://ai.google.dev/docs)

## 📈 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## ❤️ Support

If you find this gem helpful, please:
- ⭐ Star the repository
- 🐛 Report bugs
- 💡 Suggest new features
- 📝 Contribute to documentation
- 📢 Share with others

---

Made with ❤️ by [Shobhit Jain](https://github.com/shobhits7) and [contributors](https://github.com/shobhits7/gemini_craft/contributors)