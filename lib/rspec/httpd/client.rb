require "net/http"

module RSpec::Httpd
  class Client
    Get     = ::Net::HTTP::Get
    Post    = ::Net::HTTP::Post
    Put     = ::Net::HTTP::Put
    Delete  = ::Net::HTTP::Delete

    attr_reader :last_response

    attr_reader :host
    attr_reader :port

    def initialize(host:, port:)
      @host = host
      @port = port
    end

    def get(url, headers: {})
      request(Get, url, body: nil, headers: headers)
    end

    def post(url, body, headers: {})
      request(Post, url, body: body, headers: headers)
    end

    def put(url, body, headers: {})
      request(Put, url, body: body || {}, headers: headers)
    end

    def delete(url, headers: {})
      request(Delete, url, body: nil, headers: headers)
    end

    private

    require "json"

    module ResponseParser
      def self.parse(response)
        content_type = response["content-type"]

        result = if content_type&.include?("application/json")
                   JSON.parse(response.body)
                 else
                   response.body.force_encoding("utf-8").encode
                 end

        result.extend(self)
        result.__response__ = response
        result
      end

      attr_accessor :__response__

      def status
        Integer(__response__.code)
      end
    end

    def request(request_klass, url, body:, headers:)
      @last_response = do_request(request_klass, url, body: body, headers: headers)
      @last_result = nil
    end

    public

    def last_result
      @last_result ||= ResponseParser.parse(last_response)
    end

    private

    def do_request(request_klass, url, body: nil, headers:)
      Net::HTTP.start(host, port) do |http|
        request = request_klass.new url, headers

        if body
          request["Content-Type"] = "application/json"
          request.body = JSON.generate body
        end

        log_request request, body: body
        http.request request
      end
    end

    def log_request(request, body: nil)
      if body
        RSpec::Httpd.logger.info "#{request.method} #{request.uri} #{body.inspect[0..100]}"
      else
        RSpec::Httpd.logger.info "#{request.method} #{request.uri}"
      end
    end
  end
end
