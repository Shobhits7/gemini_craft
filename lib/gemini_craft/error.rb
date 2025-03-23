# frozen_string_literal: true

module GeminiCraft
  # Base error class for all GeminiCraft errors
  class Error < StandardError; end

  # Error raised when there's an issue with API requests
  class APIError < Error; end

  # Error raised when the response cannot be processed
  class ResponseError < Error; end
end
