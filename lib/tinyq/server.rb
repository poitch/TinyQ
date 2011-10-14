module TinyQ
    class Server
        attr_accessor :connections

        attr_accessor :buckets
        attr_accessor :funnels

        def initialize
            @connections = []
            @buckets = {}
            @funnels = {}
        end

        def usage
            puts "#{$0}"
            puts "version: #{TinyQ::VERSION}"
            puts " -b go into background/daemonize"
            puts " -p <port> port number to listen to (default: 64321)"
            puts " -i <ip> ip to bind to (default: 127.0.0.1)"
            puts " -d turn on debug"
            puts " -h help, this message"
        end

        def main(args)
            opt = Getopt::Std.getopts("bp:i:dh")

            if opt['h']
                usage
                exit
            end

            @ip = opt['i'] || '127.0.0.1'
            @port = opt['p'] || 64321

            if opt['d']
                $LOG.level = Logger::DEBUG
            end

            if opt['b']
                puts "Going into background"
                Daemons.daemonize
            end
            
            start
        end

        def self.start
            new().start
        end

        def start
            EventMachine::run {
                trap("TERM") { stop }
                trap("INT") { stop }
                EventMachine.epoll
                @signature = EventMachine.start_server(@ip, @port, Connection) do |con|
                    con.server = self
                    # We actually do not want to wait on clients
                    #@connections.push(con)
                end
                $LOG.info("TinyQ listening on 0.0.0.0:64321")
            }
        end


        def stop
            $LOG.info("TinyQ Exiting")
            EventMachine.stop_server(@signature)

            unless wait_for_connections_and_stop
                EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
            end
        end

        def wait_for_connections_and_stop
            if @connections.empty?
                EventMachine.stop
                true
            else
                $LOG.info("Waiting for #{@connections.size} connection(s) to finish...")
                false
            end
        end

        def bucket(name)
            bucket = @buckets[name]
            if nil == bucket
                $LOG.info("Server - Creating bucket #{name}")
                bucket = Bucket.new(name)
                @buckets[name] = bucket
            end

            bucket
        end

        def remove_connection(c)
            @connections.delete(c)
            @funnels.each do |name,funnel|
                funnel.remove_connection(c)
            end
        end

    end
end


