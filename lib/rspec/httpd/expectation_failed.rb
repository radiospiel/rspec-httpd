# rubocop:disable Metrics/AbcSize

class RSpec::Httpd::ExpectationFailed < RuntimeError
  attr_reader :original_error, :response

  def initialize(original_error, response:)
    @original_error, @response = original_error, response
  end

  def request
    response.request
  end

  def to_s
    parts = []
    parts.push(original_error.to_s)
    parts.push("=== #{request} =====================")
    parts.push("> " + request.body.gsub("\n", "\n> ")) if request.body
    parts.push("--- response ------------------------------------")
    parts.push("< " + response.body.gsub("\n", "\n< ")) if response.body
    parts.push("==================================================================")
    parts.join("\n")
  end
end
