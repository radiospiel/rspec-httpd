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

      if port_open?(host, port)
        logger.error "A process is already running on #{host}:#{port}"
        exit 2
      end

      logger.debug "Starting server: #{command}"

      # start child process in a separate process group. at exit we'll
      # kill the entire process group. This helps if the started process
      # spawns another child again.
      pid = spawn(command, pgroup: true)
      pgid = Process.getpgid(pid)

      at_exit do
        begin
          logger.debug "Terminating server in pgid #{pgid}: #{command}"
          Process.kill("TERM", -pgid)
          sleep 0.2
        rescue Errno::ESRCH
        end

        if port_open?(host, port)
          begin
            logger.debug "Killing server in pgid #{pgid}: #{command}"
            Process.kill("KILL", -pgid)
          rescue Errno::ESRCH, Errno::EPERM
          end
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
