module TinyQ
    class ClientConnection < EventMachine::Connection
        include EventMachine::Protocols::LineText2

        attr_accessor :client

        def initialize
            set_delimiter TinyQ::DELIMITER
        end

        def receive_line message
            begin
                reply = JSON.parse(message)
                @client.callbacks.each { |c| c.call(reply) }
            rescue Exception => e
                puts e
            end
        end

    end

    class Client 
        attr_accessor :callbacks

        def initialize
            @callbacks = []
        end

        def connect(host, port)
            @host, @port = host, port
            @connection = EM.connect @host, @port, TinyQ::ClientConnection
            @connection.client = self
        end

        # 
        # Public API
        #
        def put_message(bucket, message)
            command = {:Command => "PutMessages", :Bucket => bucket, :Message => message}
            @connection.send_data("#{command.to_json}#{TinyQ::DELIMITER}")
        end

        def get_message(funnel)
            command = {:Command => "GetMessages", :Funnel => funnel}
            @connection.send_data("#{command.to_json}#{TinyQ::DELIMITER}")
        end

        def onreply(&block)
            @callbacks << block
        end


        def feed_funnel(bucket, funnel)
            command = {:Command => "FeedFunnel", :Bucket => bucket, :Funnel => funnel}
            @connection.send_data("#{command.to_json}#{TinyQ::DELIMITER}")
        end

    end
end
