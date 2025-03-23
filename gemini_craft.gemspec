# frozen_string_literal: true

require_relative "lib/gemini_craft/version"

Gem::Specification.new do |spec|
  spec.name = "gemini_craft"
  spec.version = GeminiCraft::VERSION
  spec.authors = ["Shobhit Jain"]
  spec.email = ["shobjain09@gmail.com"]

  spec.summary = "A Ruby gem for generating content using Google's Gemini AI"
  spec.description = "GeminiCraft provides a simple and robust interface to generate content using Google's Gemini AI models"
  spec.homepage = "https://github.com/shobhits7/gemini_craft"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shobhits7/gemini_craft"
  spec.metadata["changelog_uri"] = "https://github.com/shobhits7/gemini_craft/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
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
end
