require "rspec/core"
require "forwardable"
require "logger"

module RSpec::Httpd
end

require_relative "httpd/version"
require_relative "httpd/server"
require_relative "httpd/client"
require_relative "httpd/config"
require_relative "httpd/expectation"

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

  def actual_response(client:, response:)
    response || client.last_result
  end

  public

  def expect_response(expected = nil, status: nil, client: nil, response: nil)
    client ||= http
    actual = actual_response(client: client, response: response)

    # do_expect_response is implemented in RSpec::Httpd::Expectation, and mixed in
    # here, because it needs access to the expect() implementation.

    request = client.last_request

    # only check status? This lets us write
    #
    #    expect_response 201
    #
    if expected.is_a?(Integer) && status.nil?
      expect(actual.status).to eq(expected)
      return
    end

    expect(actual.status).to eq(status || 200)
    unless expected.nil?
      do_expect_response_body(expected: expected, actual: actual, request: request)
    end
  end

  include RSpec::Httpd::Expectation
end
