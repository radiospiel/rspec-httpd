require "rspec/core"
require "logger"
require "expectation"

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity

module RSpec::Httpd
end

require_relative "httpd/version"
require_relative "httpd/server"
require_relative "httpd/client"
require_relative "httpd/config"
require_relative "httpd/expectation_failed"

module RSpec::Httpd
  extend self

  attr_reader :config

  # Set the configuration for the default client.
  #
  # See also: RSpec::Httpd.http
  def configure(&block)
    @config = Config.new.tap(&block)
  end

  def logger #:nodoc:
    @config.logger
  end

  # builds and returns a client.
  #
  # You can use this method to retrieve a client connection to a server
  # specified via host:, port:, and, optionally, a command.
  def client(host:, port:, command: nil)
    @clients ||= {}
    @clients[[host, port, command]] ||= begin
      Server.start!(host: host, port: port, command: command) if command
      Client.new host: host, port: port
    end
  end

  private

  # returns the default client
  #
  # The default client is the one configured via RSpec::Httpd.configure.
  def http
    config = ::RSpec::Httpd.config ||
             raise("RSpec::Httpd configuration missing; run RSpec::Httpd.configure { |config| ... }")

    client(host: config.host, port: config.port, command: config.command)
  end

  public

  def expect_response(expected = nil, status: nil, client: nil)
    if expected.nil? && block_given?
      expected = yield
    end

    expected = stringify_hash(expected) if expected.is_a?(Hash)

    client ||= http

    # only check status? This lets us write
    #
    #    expect_response 201
    #
    expected_status = expected.is_a?(Integer) && status.nil? ? expected : status || 200

    response = client.response
    request  = response.request

    if response.status != expected_status
      error_message = <<~MSG
        #{response.class}
        #{response.request.class}
        HTTP status should be #{expected_status}, but is #{response.status}, on '#{request}'
      MSG

      if response.status >= 400
        error_message += <<~MSG
          ---- response.body ----------------------------------------------------
          #{response.body}
          -----------------------------------------------------------------------
        MSG
      end

      expect(response.status).to eq(expected_status), error_message
    end

    return if expected.nil? || expected.is_a?(Integer)

    begin
      # expect! comes from the expectation gem
      expect! response.content => expected
    rescue ::Expectation::Matcher::Mismatch => e
      raise ExpectationFailed.new(e, response: response), cause: nil
    end
  end

  private

  def stringify_hash(hsh)
    return unless hsh

    hsh.inject({}) do |r, (k, v)|
      k = k.to_s if k.is_a?(Symbol)
      r.update k => v
    end
  end
end
