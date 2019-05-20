# rubocop:disable Metrics/AbcSize

class RSpec::Httpd::ExpectationFailed < RuntimeError
  attr_reader :original_error, :request, :response

  def initialize(original_error, request:, response:)
    @original_error, @request, @response = original_error, request, response
  end

  def to_s
    parts = []
    parts.push("=== #{request.method} #{request.path} =====================")
    parts.push("> " + request.body.gsub("\n", "\n> ")) if request.body
    parts.push("--- response ------------------------------------")
    parts.push("< " + response.body.gsub("\n", "\n< ")) if response.body
    parts.push("==================================================================")
    parts.join("\n")
  end
end
