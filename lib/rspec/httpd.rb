require "rspec/core"
require "forwardable"
require "logger"

module RSpec::Httpd
end

require_relative "httpd/version"
require_relative "httpd/server"
require_relative "httpd/client"
require_relative "httpd/env"

module RSpec::Httpd
  extend ::RSpec::Httpd::Env

  extend Forwardable
  delegate %i[http server client] => Env
  delegate [:logger] => Env

  private

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
