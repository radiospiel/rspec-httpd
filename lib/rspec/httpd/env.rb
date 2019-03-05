require "rspec/core"
require "logger"

module RSpec::Httpd::Env
  extend self

  attr_accessor :host
  attr_accessor :port
  attr_accessor :command

  self.host = "127.0.0.1"
  self.port = 12_345
  self.command = "bundle exec rackup -E test -p 12345"

  def logger
    @logger ||= build_logger
  end

  def build_logger
    logger = Logger.new STDERR
    logger.level = Logger::INFO
    logger.warn "*** Built logger"
    logger
  end

  def client(host:, port:, command: nil)
    @clients ||= {}
    @clients[[host, port, command]] ||= begin
      server(host: host, port: port, command: command).start! if command
      Client.new host: host, port: port
    end
  end

  def server(host:, port:, command:)
    @servers ||= {}
    @servers[[host, port, command]] ||= begin
      puts "build server #{[host, port, command].inspect}"
      Server.new(host: host, port: port, command: command)
    end
  end

  def http
    client(host: host, port: port, command: command)
  end
end
