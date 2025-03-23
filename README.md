# GeminiCraft

A Ruby gem for generating content using Google's Gemini AI.

## Installation

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

## Usage

### Configuration

Set up GeminiCraft with your Gemini API key:

```ruby
require 'gemini_craft'

GeminiCraft.configure do |config|
  config.api_key = 'your-gemini-api-key'
  config.model = 'gemini-2.0-flash'  # Optional, defaults to gemini-2.0-flash
  config.cache_enabled = true        # Optional, defaults to false
  config.cache_ttl = 3600            # Optional, cache TTL in seconds (default: 1 hour)
  config.timeout = 30                # Optional, request timeout in seconds
  config.max_retries = 3             # Optional, number of retry attempts for failed requests
end
```

Alternatively, you can set the API key via the environment variable `GEMINI_API_KEY`.

### Generating Content

Generate content with a simple prompt:

```ruby
response = GeminiCraft.generate_content("Write a short poem about Ruby programming")
puts response
```

Include a system instruction to guide the model:

```ruby
system_instruction = "You are a helpful assistant that responds in a friendly, conversational tone."
response = GeminiCraft.generate_content("What is Ruby on Rails?", system_instruction)
puts response
```

### Advanced Usage

Using additional options:

```ruby
options = {
  temperature: 0.7,
  topK: 40,
  topP: 0.95,
  maxOutputTokens: 1024
}

response = GeminiCraft.generate_content(
  "Explain quantum computing",
  "You are a quantum physics expert",
  options
)

puts response
```

Using the client directly:

```ruby
client = GeminiCraft.client
response = client.generate_content("Tell me a joke")
puts response
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shobhits7/gemini_craft. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/shobhits7/gemini_craft/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the GeminiCraft project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/shobhits7/gemini_craft/blob/main/CODE_OF_CONDUCT.md).
