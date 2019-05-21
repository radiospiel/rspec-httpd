require "net/http"
require "json"

module RSpec::Httpd
  class Client
    # host and port. Set at initialization
    attr_reader :host
    attr_reader :port

    def initialize(host:, port:)
      @host, @port = host, port
    end

    # request, response, and status, set during a request/response cycle
    attr_reader :request
    attr_reader :response

    def status
      Integer(response.code)
    end

    # returns the headers of the latest response
    def headers
      @headers ||= HeadersHash.new(response)
    end

    # returns the parsed response of the latest request
    def result
      @result ||= ResponseParser.parse(response)
    end

    # A GET request
    def get(url, headers: {})
      run_request(::Net::HTTP::Get, url, body: nil, headers: headers)
    end

    # A HEAD request
    def head(url, headers: {})
      run_request(::Net::HTTP::Head, url, body: nil, headers: headers)
    end

    # A POST request
    def post(url, body, headers: {})
      run_request(::Net::HTTP::Post, url, body: body, headers: headers)
    end

    # A PUT request
    def put(url, body, headers: {})
      run_request(::Net::HTTP::Put, url, body: body || {}, headers: headers)
    end

    # A DELETE request
    def delete(url, headers: {})
      run_request(::Net::HTTP::Delete, url, body: nil, headers: headers)
    end

    private

    def run_request(request_klass, url, body:, headers:)
      # reset all results from previous run
      @request = @response = @headers = @result = nil

      @response = Net::HTTP.start(host, port) do |http|
        @request = build_request(request_klass, url, body: body, headers: headers)

        log_request(request)
        http.request(request)
      end
    end

    def build_request(request_klass, url, body:, headers:)
      request_klass.new(url, headers).tap do |request|
        if body
          request["Content-Type"] = "application/json"
          request.body = JSON.generate(body)
        end
      end
    end

    def log_request(request)
      if request.body
        RSpec::Httpd.logger.info "#{request.method} #{request.path} #{request.body.inspect[0..100]}"
      else
        RSpec::Httpd.logger.info "#{request.method} #{request.path}"
      end
    end

    class HeadersHash < Hash
      def initialize(response)
        response.each_header do |k, v|
          case self[k]
          when Array then self[k].concat v
          when nil   then self[k] = v
          else            self[k].concat(v)
          end
        end
      end

      def [](key)
        super key.downcase
      end

      private

      def []=(key, value)
        super key.downcase, value
      end
    end

    module ResponseParser
      def self.parse(response)
        return nil if response.body.nil?

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
  end
end
