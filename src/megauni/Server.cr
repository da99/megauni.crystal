
module MEGAUNI

  class Server

    PORTS_DIR = File.expand_path("#{__DIR__}/../../tmp/out/megauni.ports")
    MODELS = Set{Root}

    # =============================================================================
    # Class:
    # =============================================================================

    def self.stop_all
      servers = [] of Server::Status
      running_servers.each { |ss|
        if ss.running?
          Process.kill(Signal::TERM, ss.pid)
          servers << ss
        else
          DA_Dev.orange! "=== {{Already closed}}: port BOLD{{#{ss.port}}}, pid BOLD{{#{ss.pid}}}"
        end
      }

      limit = 1
      while limit < 50
        if servers.all? { |x| !x.running? }
          break
        end
        limit += 1
        sleep 0.1
      end

      servers.each { |ss|
        if ss.running?
          DA_Dev.orange! "=== {{Still up}} (despite sending TERM signal): port BOLD{{#{ss.port}}}, pid BOLD{{#{ss.pid}}}"
        else
          DA_Dev.green! "=== {{Close}} successful: port BOLD{{#{ss.port}}}, pid BOLD{{#{ss.pid}}}"
        end
      }
    end

    def self.running_servers(port : Int32)
      running_servers.select { |server_status|
        server_status.running? && server_status.port == port
      }
    end

    def self.running_servers
      Dir.mkdir_p(PORTS_DIR)
      count = [] of Server::Status
      Dir.glob("#{PORTS_DIR}/*").each { |file|
        ss = Server::Status.new(file)
        count.push(ss) if ss.running?
      }
      count
    end

    # =============================================================================
    # Instance:
    # =============================================================================

    getter server : HTTP::Server
    getter port : Int32

    def initialize(@port = 3000)
      @server = HTTP::Server.new(port) do |ctx|
        Route.route!(ctx)
      end
    end # === def self.start

    def port_file
      File.join(PORTS_DIR, port.to_s)
    end

    def close
      @server.close
      File.delete(port_file)
      STDERR.puts
      STDERR.puts DA_Dev::Colorize.green("=== {{Closed}} server on port BOLD{{#{port}}}, pid BOLD{{#{Process.pid}}} ===")
    end

    def listen
      Dir.mkdir_p(PORTS_DIR)
      current = Server.running_servers(port)
      if current.size > 0
        current.each { |ss|
          DA_Dev.red! "!!! {{Server already running}}: port BOLD{{#{ss.port}}}, pid BOLD{{#{ss.pid}}}"
        }
        exit 1
      end

      File.write(port_file, Process.pid.to_s) unless File.exists?(port_file)

      Signal::INT.trap {
        Signal::INT.reset
        close
        exit 0
      }

      Signal::TERM.trap {
        Signal::TERM.reset
        close
        exit 0
      }

      DA_Dev.orange! "=== {{Starting}} server on port BOLD{{#{port}}}, pid BOLD{{#{Process.pid}}}"
      @server.listen
    end # === def listen

    struct Status

      getter port : Int32
      getter pid : Int32

      def initialize(file : String)
        @port = File.basename(file).to_i
        raw   = File.read(file).strip
        @pid  = (raw[/\A[0-9]+\Z/]?) ? raw.to_i : -1
      end # === def initialize

      def valid?
        @pid > 0
      end

      def running?
        valid? && Process.exists?(@pid)
      end

    end # === struct Status
  end # === module Server

end # === module MEGAUNI



