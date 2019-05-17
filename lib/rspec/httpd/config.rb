class RSpec::Httpd::Config
  attr_accessor :host
  attr_accessor :port
  attr_accessor :command

  def initialize
    self.host = "127.0.0.1"
    self.port = 12_345
    self.command = "bundle exec rackup -E test -p 12345"
  end
end
