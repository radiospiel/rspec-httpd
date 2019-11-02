class RSpec::Httpd::Config
  attr_accessor :host
  attr_accessor :port
  attr_accessor :command
  attr_accessor :logger

  def initialize
    self.host = "127.0.0.1"
    self.port = 12_345
    self.command = "bundle exec rackup -E test -p 12345"
    self.logger = Logger.new(STDERR).tap { |logger| logger.level = Logger::INFO }
  end
end
