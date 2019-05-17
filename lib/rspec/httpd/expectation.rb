require "rspec/core"
require "forwardable"
require "logger"

module RSpec::Httpd::Expectation
  def do_expect_last_request(expected:, client:)
    actual = client.result

    ctx = {
      request: client.request, actual: actual, expected: expected
    }

    case expected
    when Regexp then expect(actual).to match(expected), -> { format_failure SHOULD_MATCH_ERROR, ctx }
    when Hash   then expect(actual).to include(expected), -> { format_failure SHOULD_INCLUDE_ERROR, ctx }
    else             expect(actual).to eq(expected), -> { format_failure SHOULD_EQUAL_ERROR, ctx }
    end
  end

  SHOULD_MATCH_ERROR    = "%request -- %actual should match %expected".freeze
  SHOULD_INCLUDE_ERROR  = "%request -- %actual should include %expected".freeze
  SHOULD_EQUAL_ERROR    = "%request -- %actual should equal %expected".freeze

  private

  def format_failure(format, ctx)
    format.gsub(/\%(\S+)/) do
      value = ctx.fetch(Regexp.last_match(1).to_sym)
      case value
      when Net::HTTPGenericRequest
        request = value
        s = "#{request.method} #{request.path}"
        s += " body:#{request.body.inspect}" if request.body
        s
      else
        value.inspect
      end
    end
  end
end
