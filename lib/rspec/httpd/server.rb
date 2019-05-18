# rubocop:disable Lint/HandleExceptions

require "socket"
require "timeout"

module RSpec::Httpd
  module Server
    MAX_STARTUP_TIME = 10

    extend self

    # builds and returns a server object.
    #
    # You can use this method to retrieve a client connection to a server
    # specified via host:, port:, and, optionally, a command.
    def start!(host:, port:, command:)
      @servers ||= {}
      @servers[[host, port, command]] ||= do_start(host, port, command)
    end

    private

    def do_start(host, port, command)
      logger = RSpec::Httpd.logger
      logger.debug "Starting server: #{command}"

      pid = spawn(command)

      at_exit do
        begin
          logger.debug "Stopping server at pid #{pid}: #{command}"
          Process.kill("KILL", pid)
          sleep 0.2
        rescue Errno::ESRCH
        end

        logger.warn "Cannot stop server at pid #{pid}: #{command}" if port_open?(host, port)
        exit 0
      end

      unless wait_for_server(host: host, port: port, pid: pid, timeout: MAX_STARTUP_TIME)
        logger.error "server didn't start at http://#{host}:#{port} pid #{pid}: #{command}"
        exit 1
      end

      logger.info "Started server at pid #{pid}: #{command}"
      pid
    end

    def wait_for_server(host:, port:, pid:, timeout:)
      while timeout > 0
        sleep 0.1
        return true if port_open?(host, port)
        return false if Process.waitpid(pid, Process::WNOHANG)

        timeout -= 0.1
        next if timeout > 0

        return false
      end
    end

    def port_open?(host, port)
      Timeout.timeout(0.01) do
        s = TCPSocket.new(host, port)
        s.close
        return true
      end
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error
      false
    end
  end
end
