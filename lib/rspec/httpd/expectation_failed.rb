class RSpec::Httpd::ExpectationFailed < RuntimeError
  attr_reader :original_error, :request

  def initialize(original_error, request)
    @original_error, @request = original_error, request
  end

  def to_s
    "#{request_info}: #{original_error}"
  end

  private

  def request_info
    request_info = "#{request.method} #{request.path}"
    return request_info unless request.body

    "#{request_info}#{body_info(parsed_body(body) || body)}"
  end

  def parsed_body(body)
    JSON.parse(body)
  rescue StandardError
    nil
  end

  def body_info(body)
    body = parsed_body(body) || body

    case body
    when Hash
      body.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
    else
      body.inspect
    end
  end
end
