# rubocop:disable Lint/HandleExceptions
# rubocop:disable Metrics/AbcSize

require "socket"
require "timeout"

module RSpec
end

module RSpec::Httpd
  module Server
    MAX_STARTUP_TIME = 10

    extend self

    def logger
      # If this file is required as-is, without loading all of rspec/httpd,
      #  ::RSpec::Httpd does not provide a logger. In that case we polyfill
      # a default logger to STDERR.
      #
      # Doing so lets use this file as is; which lets one use the
      #
      #   RSpec::Httpd::Server.start! ...
      #
      # method.
      if ::RSpec::Httpd.respond_to?(:logger)
        ::RSpec::Httpd.logger
      else
        @logger ||= ::Logger.new(STDERR, level: :info)
      end
    end

    # builds and returns a server object.
    #
    # You can use this method to retrieve a client connection to a server
    # specified via host:, port:, and, optionally, a command.
    def start!(host: "0.0.0.0", port:, command:, logger: nil)
      @servers ||= {}
      @servers[[host, port, command]] ||= command ? do_start(host, port, command) : check_server(host, port)
      @logger = logger if logger
    end

    private

    def check_server(host, port)
      unless wait_for_server(host: host, port: port, timeout: MAX_STARTUP_TIME)
        logger.error "cannot reach server at http://#{host}:#{port}"
        exit 1
      end
    end

    def do_start(host, port, command)
      if port_open?(host, port)
        logger.error "A process is already running on #{host}:#{port}"
        exit 2
      end

      STDERR.puts <<~MSG
        ==== Starting server ================================================================
        #{command}
        =====================================================================================
      MSG

      # start child process in a separate process group. at exit we'll
      # kill the entire process group. This helps if the started process
      # spawns another child again.
      pid = spawn(command, pgroup: true)
      pgid = Process.getpgid(pid)

      # Install an at_exit handler. This will kill the server. The command
      # argument is passed in for logging only.
      at_exit do
        kill_server "TERM", pgid, command: command, sleep: 0.2 if port_open?(host, port)
        kill_server "KILL", pgid, command: command, sleep: 0.2 if port_open?(host, port)

        logger.warn "Cannot stop server at pid #{pid}: #{command}" if port_open?(host, port)
      end

      unless wait_for_server(host: host, port: port, pid: pid, timeout: MAX_STARTUP_TIME)
        logger.error "server didn't start at http://#{host}:#{port} pid #{pid}: #{command}"
        exit! 1
      end

      logger.info "Started server at pid #{pid}: #{command}"
      pid
    end

    def kill_server(signal, pgid, command:, sleep: nil)
      logger.debug "Kill server in pgid #{pgid} w/#{signal}: #{command}"

      Process.kill(signal, -pgid)
      Kernel.sleep(sleep) if sleep
    rescue Errno::ESRCH, Errno::EPERM
    end

    def wait_for_server(host:, port:, pid: nil, timeout:)
      while timeout > 0
        sleep 0.1
        return true if port_open?(host, port)
        return false if pid && Process.waitpid(pid, Process::WNOHANG)

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
