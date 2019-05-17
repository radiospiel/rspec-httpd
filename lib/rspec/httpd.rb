require "rspec/core"
require "forwardable"
require "logger"

module RSpec::Httpd
end

require_relative "httpd/version"
require_relative "httpd/server"
require_relative "httpd/client"
require_relative "httpd/config"

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
    return response if response

    client ? client.last_result : http.last_result
  end

  public

  def expect_response(expected = nil, status: nil, client: nil, response: nil)
    actual = actual_response(client: client, response: response)

    if expected.is_a?(Integer) && status.nil?
      expect(actual.status).to eq(expected)
      return
    end

    status ||= 200
    expect(actual.status).to eq(status)
    expect(actual).to eq(expected) unless expected.nil?
  end
end
