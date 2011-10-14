module TinyQ
    #
    # Funnel will receive messages on the internal queue and will dispatch
    # to subscribers
    #
    class Funnel
        attr_accessor :name
        attr_reader :queue
        attr_accessor :buckets
        attr_accessor :subscribers
        attr_accessor :broadcaster

        def initialize(n, b = false)
            @name = n
            @broadcaster = b
            @queue = EventMachine::Queue.new
            @subscribers = {}
            @buckets = []

            cb = Proc.new do |event|
                $LOG.debug("Funnel #{@name} - Callback")
                if !@subscribers.empty?
                    # OK we can dequeue from bucket since we have somewhere to send it
                    bucket = event[:Bucket]
                    message,message_id = bucket.dequeue(self)

                    $LOG.debug("Funnel #{@name} - Callback got '#{message_id}'")

                    if message != nil
                        if @broadcaster
                            $LOG.debug("Funnel #{@name} - Broadcasting #{message_id}")
                            @subscribers.each do |c,subscriber|
                                if subscriber.put_message(bucket, self, message, message_id)
                                    # Subscriber is done removing
                                    $LOG.debug("Funnel #{@name} - Subscriber received requested count")
                                    self.remove_connection(c)
                                end
                            end
                        else
                            $LOG.debug("Funnel #{@name} - Unicasting #{message_id}")
                            c = @subscribers.keys[0]
                            subscriber = @subscribers[c]
                            $LOG.debug("Funnel #{@name} - Unicasting to #{subscriber.connection.ip}:#{subscriber.connection.port}")
                            if subscriber.put_message(bucket, self, message, message_id)
                                # Subscriber is done removing
                                $LOG.debug("Funnel #{@name} - Subscriber #{subscriber.connection.ip}:#{subscriber.connection.port} received requested count")
                                self.remove_connection(c)
                            end
                        end
                    else
                        $LOG.debug("Funnel #{@name} - Callback noop")
                    end
                end

                # Wait for next event
                @queue.pop &cb
            end

            @queue.pop &cb
        end

        # Method called by bucket when messages are available
        def notify(bucket)
            @queue.push({:Event => "New Message", :Bucket => bucket})
        end

        def add_connection(c,n = 1)
            subscriber = @subscribers[c]
            if nil == subscriber
                subscriber = Subscriber.new(c,n)
                @subscribers[c] = subscriber
            end

            # At this point, we need to see if any buckets we are connected to
            # have pending messages
            @buckets.each do |bucket|
                if !bucket.messages.empty?
                    self.notify(bucket)
                end
            end
        end

        def remove_connection(c)
            $LOG.debug("Funnel #{@name} - Removing subscriber #{c.ip}:#{c.port}")
            @subscribers.delete(c)
        end

    end
end


