# frozen_string_literal: true

require_relative "lib/gemini_craft/version"

Gem::Specification.new do |spec|
  spec.name = "gemini_craft"
  spec.version = GeminiCraft::VERSION
  spec.authors = ["Shobhit Jain"]
  spec.email = ["shobjain09@gmail.com"]

  spec.summary = "A Ruby gem for generating content using Google's Gemini AI"
  spec.description = "GeminiCraft provides a simple and robust interface to generate content using Google's Gemini AI models with support for streaming, function calling, and advanced caching"
  spec.homepage = "https://github.com/shobhits7/gemini_craft"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shobhits7/gemini_craft"
  spec.metadata["changelog_uri"] = "https://github.com/shobhits7/gemini_craft/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/shobhits7/gemini_craft/issues"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/gemini_craft"

  spec.files = Dir[
    "lib/**/*",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md",
    "CODE_OF_CONDUCT.md"
  ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "faraday-retry", "~> 2.2"

  spec.add_development_dependency "dotenv", "~> 2.8"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-performance", "~> 1.17"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "yard", "~> 0.9"

  spec.metadata["rubygems_mfa_required"] = "true"
end
