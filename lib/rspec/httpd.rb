require "rspec/core"
require "forwardable"
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
    @logger ||= Logger.new(STDERR).tap { |logger| logger.level = Logger::INFO }
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

    client ||= http

    # only check status? This lets us write
    #
    #    expect_response 201
    #
    if expected.is_a?(Integer) && status.nil?
      expect(client.status).to eq(expected)
      return
    end

    # do_expect_last_request is implemented in RSpec::Httpd::Expectation, and mixed in
    # here, because it needs access to the expect() implementation.

    expect(client.status).to eq(status || 200)
    return if expected.nil?

    begin
      # expect! comes from the expectation gem
      expect! client.result => expected
    rescue ::Expectation::Matcher::Mismatch
      raise ExpectationFailed.new($!, request: client.request, response: client.response), cause: nil
    end
  end
end
