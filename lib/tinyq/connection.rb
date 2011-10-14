module TinyQ
    class Connection < EventMachine::Connection
        attr_accessor :server
        attr_reader :ip
        attr_reader :port

        include EventMachine::Protocols::LineText2


        def initialize
            set_delimiter TinyQ::DELIMITER
        end

        def post_init
            @port, *ip_parts = get_peername[2,6].unpack "nC4"
            @ip = ip_parts.join('.')
            
            $LOG.info("#{@ip}:#{@port} connected")
        end

        def receive_line line
            process_message line
        end

        def reply rsp
            send_data("#{rsp.to_json}#{TinyQ::DELIMITER}")
        end

        def ok
            response = {:Status => "OK"}
            reply(response)
        end

        def failed errmsg
            response = {:Status => "Failed", :Message => errmsg}
            reply(response)
        end


        def process_message data
            begin
                request = JSON.parse(data)
                $LOG.debug("Request: #{request}")
                if request.has_key? 'Command'
                    $LOG.debug("Command - #{request['Command']}")

                    case request['Command']
                    when "PutMessages"
                        # Put message in a bucket
                        if request.has_key? 'Bucket'
                            bucket = @server.bucket(request['Bucket'])

                            if request['Message'].kind_of?(Array)
                                request['Message'].each do |message|
                                    Journal.instance.event({:Event=>"PutMessage"})
                                    bucket.put_message(message)
                                end
                            else
                                Journal.instance.event({:Event=>"PutMessage"})
                                bucket.put_message(request['Message'])
                            end

                            ok()
                        else
                            failed("Parameter Bucket missing")
                        end
                    when "FeedFunnel"
                        # Feed Bucket to Funnel
                        if request.has_key? 'Bucket' and request.has_key? 'Funnel'
                            # Hook up a funnel to a bucket
                            bucket = @server.bucket(request['Bucket'])
                            funnel = @server.funnels[request['Funnel']]
                            if nil != funnel
                                bucket.feed_funnel(funnel)
                            else
                                if request.has_key? 'Broadcaster'
                                    funnel = bucket.funnel(request['Funnel'], request['Broadcaster'])
                                else
                                    funnel = bucket.funnel(request['Funnel'])
                                end
                                @server.funnels[request['Funnel']] = funnel
                            end

                            ok()
                        else
                            failed("Parameter Bucket or Funnel missing")
                        end
                    when "GetMessages"
                        # Get Messages from Funnel
                        if request.has_key? 'Funnel'
                            funnel = @server.funnels[request['Funnel']]
                            if nil == funnel
                                $LOG.warn("Funnel was never fed...")
                                failed("Funnel was never fed")
                            else
                                if request.has_key? 'Ack'
                                    ok()
                                end

                                if request.has_key? 'Count'
                                    funnel.add_connection(self, request['Count'])
                                else
                                    funnel.add_connection(self)
                                end
                            end
                        else
                            failed("Parameter Funnel missing")
                        end
                    when "GetInfo"
                        if request.has_key? 'Bucket'
                            bucket = @server.bucket(request['Bucket'])

                            response = {
                                :Status => 'OK',
                                :Bucket => {
                                :Name => bucket.name,
                                :MessageCount => bucket.messages.size,
                                :Funnels => [],
                            }
                            }

                            bucket.funnels.each do |n,funnel|
                                response[:Bucket][:Funnels].push({
                                    :Name => funnel.name,
                                    :MessageCount => funnel.messages.size,
                                    :SubscriberCount => funnel.subscribers.size,
                                })
                            end

                            reply(response)

                        elsif request.has_key? 'Funnel'
                        else
                            failed("Parameter Funnel or Bucket missing")
                        end
                    else
                        # Unsupported command
                        failed("Unsupported command")
                    end

                else
                    # Did not understand
                    failed("Parameter Command missing")
                end
            rescue Exception => e
                $LOG.error("Failed #{e}")
                failed("Internal error #{e}")
            end
        end

        def unbind
            $LOG.info("#{@ip}:#{@port} disconnected")
 
            @server.remove_connection(self)
        end

    end
end


