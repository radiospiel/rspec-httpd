require "simple-http"

module RSpec::Httpd
  class Client < Simple::HTTP
    def initialize(host:, port:)
      super()
      self.base_url = "http://#{host}:#{port}"
    end

    attr_reader :response

    def content
      @response.content
    end

    private

    def execute_request(request, max_redirections: 10)
      @response = super(request, max_redirections: max_redirections)
    end
  end
end
