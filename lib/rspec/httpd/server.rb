# rubocop:disable Lint/HandleExceptions

require "socket"
require "timeout"

module RSpec::Httpd
  class Server
    MAX_SLEEP = 10

    def running?
      @running
    end

    def initialize(host:, port:, command:)
      @host = host
      @port = port
      @command = command
      @running = false
    end

    def start!
      return if running?

      log "Starting Server (using '#{@command}')"

      pid = spawn(@command)
      at_exit do
        Process.kill("KILL", pid)
        sleep 0.2
        die "Cannot stop Server (at pid #{pid})" if port_open?
        log "Stopped Server"
      end

      max_sleep = MAX_SLEEP

      while max_sleep > 0
        sleep 0.1
        break if port_open?

        max_sleep -= 0.1
        next if max_sleep > 0

        die "Cannot start Server (using '#{@command}')"
      end

      log "Started Server (using '#{@command}')"
      @running = true
    end

    private

    def die(msg)
      log msg
      exit
    end

    def log(msg)
      STDERR.puts msg
    end

    def port_open?
      begin
        Timeout.timeout(0.01) do
          s = TCPSocket.new(@host, @port)
          s.close
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          return false
        end
      rescue Timeout::Error
      end

      false
    end
  end
end
