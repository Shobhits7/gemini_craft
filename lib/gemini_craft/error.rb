# frozen_string_literal: true

module GeminiCraft
  # Base error class for all GeminiCraft errors
  class Error < StandardError; end

  # Error raised when there's an issue with API requests
  class APIError < Error; end

  # Error raised when the response cannot be processed
  class ResponseError < Error; end

  # Error raised when authentication fails
  class AuthenticationError < APIError; end

  # Error raised when authorization fails
  class AuthorizationError < APIError; end

  # Error raised when the requested resource is not found
  class NotFoundError < APIError; end

  # Error raised when rate limits are exceeded
  class RateLimitError < APIError; end

  # Error raised for client-side errors (4xx)
  class ClientError < APIError; end

  # Error raised for server-side errors (5xx)
  class ServerError < APIError; end

  # Error raised when requests timeout
  class TimeoutError < APIError; end

  # Error raised when connection fails
  class ConnectionError < APIError; end

  # Error raised when streaming fails
  class StreamingError < APIError; end
end
