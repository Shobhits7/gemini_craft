# Changelog

## [0.2.0] - 2025-05-26

### 🚀 Added
- **Streaming Support**: Real-time content generation with `stream_content` method
  - Added `stream: true` option to `generate_content` method
  - Streaming responses return `Enumerator` for chunk-by-chunk processing
  - Perfect for chatbots and live content generation
- **Function Calling**: Full support for Gemini's function calling capabilities
  - New `generate_with_functions` method for AI-driven function execution
  - Structured function parameter validation
  - Support for multiple function calls in single request
- **Enhanced Error Handling**: Comprehensive error type system
  - `AuthenticationError` for invalid API keys
  - `AuthorizationError` for permission issues
  - `RateLimitError` for quota exceeded scenarios
  - `TimeoutError` for request timeouts
  - `ConnectionError` for network failures
  - `StreamingError` for streaming-specific issues
  - `NotFoundError` for missing models/endpoints
  - `ClientError` and `ServerError` for 4xx/5xx responses
- **Logging Support**: Integrated logging system
  - Configurable log levels (`:debug`, `:info`, `:warn`, `:error`, `:fatal`)
  - Automatic Rails logger integration
  - Request/response logging with metadata
  - Performance metrics logging
- **Connection Pooling**: HTTP connection optimization
  - Configurable connection pool size
  - Keep-alive timeout configuration
  - Better resource management for high-throughput apps
- **Enhanced Caching System**: Intelligent cache management
  - Thread-safe cache operations
  - Automatic cleanup of expired entries
  - LRU (Least Recently Used) eviction policy
  - Cache statistics with `cache_stats` method
  - Manual cache clearing with `clear_cache` method
  - Background cleanup thread for maintenance

### 🔧 Changed
- **Configuration System**: Extended configuration options
  - Added `logger` and `log_level` for logging control
  - Added `streaming_enabled` for streaming feature toggle
  - Added `connection_pool_size` and `keep_alive_timeout` for performance
  - Enhanced validation with detailed error messages
- **Client Architecture**: Improved client implementation
  - Better connection management with pooling
  - Enhanced retry logic with specific retry conditions
  - Improved error handling with contextual information
  - Thread-safe operations throughout
- **Cache Implementation**: Complete cache system overhaul
  - Moved from simple hash to sophisticated cache with cleanup
  - Added timestamp and access time tracking
  - Implemented automatic maintenance routines
  - Added statistics and monitoring capabilities
- **API Integration**: Enhanced Gemini API interaction
  - Better request/response handling
  - Improved streaming protocol implementation
  - Enhanced function calling protocol support
  - More robust error parsing and handling

### 🚀 Improved
- **Performance**: Significant performance improvements
  - Connection pooling reduces latency for multiple requests
  - Intelligent caching reduces redundant API calls
  - Optimized retry logic prevents unnecessary delays
  - Background cache cleanup prevents memory bloat
- **Reliability**: Enhanced reliability and stability
  - Better error recovery mechanisms
  - Improved timeout handling
  - More robust streaming implementation
  - Thread-safe operations prevent race conditions
- **Developer Experience**: Better development experience
  - Comprehensive logging for debugging
  - Detailed error messages with context
  - Cache statistics for monitoring
  - Rails integration helpers
- **Documentation**: Enhanced documentation and examples
  - Updated README with comprehensive usage examples
  - Added function calling examples
  - Added streaming implementation guides
  - Added Rails integration patterns

### 🔄 Migration Notes
- All existing v0.1.x code continues to work without changes
- New features are opt-in and don't affect existing functionality
- Configuration remains backward compatible
- Error handling is enhanced but doesn't break existing rescue blocks

## [0.1.3] - 2025-03-25

### 🐛 Fixed
- Fixed issue with response parsing when API returns empty candidates array
- Improved error messages for network connectivity issues
- Fixed cache key generation for requests with special characters
- Resolved thread safety issue in configuration management

### 🔧 Changed
- Updated Faraday dependency to allow versions 2.7.x
- Improved retry logic to handle more transient error types
- Enhanced timeout handling for slow network connections
- Better handling of malformed JSON responses

### 📝 Documentation
- Added more comprehensive error handling examples
- Updated API documentation with clearer parameter descriptions
- Added troubleshooting section for common issues
- Improved code examples formatting

## [0.1.2] - 2025-03-20

### 🐛 Fixed
- Fixed gemspec file inclusion pattern
- Resolved issue with missing require statements in some environments
- Fixed default configuration values not being properly applied
- Corrected cache TTL calculation bug

### 🔧 Changed
- Improved error messages for configuration validation
- Enhanced request timeout handling
- Better handling of API response edge cases
- Optimized cache key generation algorithm

### 📦 Dependencies
- Updated faraday-retry to version 2.2.x
- Added development dependency version constraints
- Improved bundler compatibility

## [0.1.1] - 2025-03-18

### 🐛 Fixed
- Fixed require path issues in Ruby 3.1+
- Resolved compatibility issue with older Faraday versions
- Fixed cache invalidation timing bug
- Corrected API endpoint URL construction

### 🔧 Changed
- Improved gem loading performance
- Enhanced configuration validation messages
- Better default values for timeout settings
- Optimized memory usage for large responses

### 📝 Documentation
- Fixed typos in README examples
- Added missing code blocks in documentation
- Improved installation instructions
- Added FAQ section

## [0.1.0] - 2025-03-15

### 🎉 Initial Release

### ✨ Features
- **Core Content Generation**: Basic text generation using Gemini API
  - Support for simple text prompts
  - System instruction support for context setting
  - Customizable generation parameters (temperature, topK, topP, maxTokens)
- **Configuration Management**: Flexible configuration system
  - Environment variable support for API key (`GEMINI_API_KEY`)
  - Configurable API endpoints and model selection
  - Timeout and retry configuration
- **Caching System**: Simple in-memory caching
  - Configurable cache TTL (time-to-live)
  - Automatic cache key generation
  - Optional caching with easy enable/disable
- **Error Handling**: Basic error handling
  - API error detection and reporting
  - Network timeout handling
  - Configuration validation
- **HTTP Client**: Robust HTTP client implementation
  - Built on Faraday with retry middleware
  - Configurable timeouts and retry policies
  - JSON request/response handling
- **Gem Infrastructure**: Professional gem setup
  - RSpec test suite with comprehensive coverage
  - RuboCop code style enforcement
  - GitHub Actions CI/CD pipeline
  - Semantic versioning
  - MIT license
  - Code of conduct and contributing guidelines

### 🔧 Configuration Options
- `api_key`: Gemini API key (required)
- `model`: Gemini model selection (default: "gemini-2.0-flash")
- `api_base_url`: API endpoint URL
- `timeout`: Request timeout in seconds (default: 30)
- `cache_enabled`: Enable/disable response caching (default: false)
- `cache_ttl`: Cache time-to-live in seconds (default: 3600)
- `max_retries`: Maximum retry attempts (default: 3)

### 📦 Dependencies
- `faraday ~> 2.7`: HTTP client library
- `faraday-retry ~> 2.2`: Retry middleware for Faraday

### 🧪 Development Dependencies
- `rspec ~> 3.12`: Testing framework
- `rubocop ~> 1.50`: Code style enforcement
- `webmock ~> 3.18`: HTTP request mocking for tests
- `simplecov ~> 0.22`: Code coverage reporting
- `yard ~> 0.9`: Documentation generation
- `dotenv ~> 2.8`: Environment variable management

### 📖 Documentation
- Comprehensive README with usage examples
- API documentation with YARD
- Contributing guidelines
- Code of conduct
- MIT license

### 🏗️ Project Structure
```
gemini_craft/
├── lib/
│   ├── gemini_craft.rb           # Main module
│   └── gemini_craft/
│       ├── version.rb            # Version management
│       ├── configuration.rb      # Configuration class
│       ├── client.rb            # API client
│       ├── cache.rb             # Caching system
│       └── error.rb             # Error classes
├── spec/                        # Test suite
├── examples/                    # Usage examples
├── README.md                    # Documentation
├── CHANGELOG.md                 # This file
├── LICENSE.txt                  # MIT license
└── gemini_craft.gemspec        # Gem specification
```

---

## Version History Summary

| Version | Release Date | Key Features |
|---------|-------------|--------------|
| **0.2.0** | 2025-05-26 | 🌊 Streaming, 🔧 Functions, 📊 Enhanced Errors, 📝 Logging |
| **0.1.3** | 2025-03-25 | 🐛 Bug fixes, 🔧 Improvements |
| **0.1.2** | 2025-03-20 | 🐛 Stability fixes, 📦 Dependencies |
| **0.1.1** | 2025-03-18 | 🐛 Compatibility fixes |
| **0.1.0** | 2025-03-15 | 🎉 Initial release |

## Upgrade Guide

### From 0.1.x to 0.2.0

**Backward Compatibility**: All existing code continues to work without changes.

**New Features Available**:
```ruby
# Streaming (new in 0.2.0)
GeminiCraft.stream_content("Tell me a story").each { |chunk| print chunk }

# Function calling (new in 0.2.0)
result = GeminiCraft.generate_with_functions(prompt, functions)

# Enhanced error handling (new in 0.2.0)
rescue GeminiCraft::RateLimitError => e
  # Handle rate limiting specifically
end

# Enhanced configuration (new in 0.2.0)
GeminiCraft.configure do |config|
  config.logger = Rails.logger
  config.streaming_enabled = true
  config.connection_pool_size = 10
end
```

**Optional Migrations**:
1. **Enable Enhanced Caching**: Update configuration to use new cache features
2. **Add Logging**: Configure logger for better debugging
3. **Enable Streaming**: Set `streaming_enabled = true` for streaming features
4. **Optimize Performance**: Configure connection pooling for high-traffic apps

## Contributing

### Changelog Guidelines

When contributing, please update this changelog:

1. **Add entries under [Unreleased]** section
2. **Use semantic versioning** for releases
3. **Follow format**: `### Category` followed by bullet points
4. **Categories**: Added, Changed, Deprecated, Removed, Fixed, Security
5. **Be descriptive**: Include context and impact of changes
6. **Link issues/PRs**: Reference relevant GitHub issues

### Release Process

1. Move unreleased changes to new version section
2. Update version in `lib/gemini_craft/version.rb`
3. Commit changes with format: "Bump version to X.Y.Z"
4. Create git tag: `git tag vX.Y.Z`
5. Push tag: `git push origin vX.Y.Z`
6. Build and release gem: `gem build && gem push gemini_craft-X.Y.Z.gem`
7. Create GitHub release with changelog content
