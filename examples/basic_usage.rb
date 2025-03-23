# frozen_string_literal: true

require "gemini_craft"

# Configure with your Gemini API key
GeminiCraft.configure do |config|
  config.api_key = "API_KEY" # Replace with your actual API key
  # Or set the GEMINI_API_KEY environment variable and remove this line
end

# Try generating some content
puts "Generating content with Gemini..."
response = GeminiCraft.generate_content("Write a short poem about coding in Ruby")
puts "Response: #{response}"

# Try with a system instruction
puts "\nGenerating content with system instruction..."
system_instruction = "You are a helpful programming assistant that writes concise, elegant code."
response = GeminiCraft.generate_content("Show me how to sort an array in Ruby", system_instruction)
puts "Response: #{response}"
