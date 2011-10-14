module TinyQ
    class Subscriber
        attr_accessor :connection
        attr_reader :queue
        attr_reader :requested
        attr_accessor :count
        attr_reader :messages
        attr_reader :message_ids

        def initialize(c,n = 1)
            @connection = c
            @requested = @count = n
            @queue = EventMachine::Queue.new
            @messages = []
            @message_ids = {}

            cb = Proc.new do |event|
                $LOG.debug("Subscriber #{@connection.ip}:#{@connection.port} - Queue callback")

                response = { :Messages => @messages }

                connection.reply(response)
                
                # Only at that point should the message be removed from the bucket!
                @message_ids.each do |message_id,info|
                    bucket = info[:Bucket]
                    funnel = info[:Funnel]

                    bucket.message_sent(funnel, message_id)
                end


                @queue.pop &cb
            end

            @queue.pop &cb
        end

        def put_message(bucket, funnel, message, message_id)
            @messages.push(message)
            @message_ids[message_id] = {
                :Funnel => funnel,
                :Bucket => bucket
            }

            if @messages.size == @requested
                # We have everything now, so we can send all messages to subscriber
                event = {
                    :Event => "New Message",
                    :Funnel => funnel,
                    :Bucket => bucket,
                    :MessageID => message_id
                }
                @queue.push(event)
                true
            else
                false
            end
        end
    end
end


