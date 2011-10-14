module TinyQ
    #
    # Bucket, messages get dropped into the bucket and forwarded
    # to the different funnels connected to that bucket
    #
    class Bucket
        attr_accessor :name

        attr_reader :messages
        attr_reader :message_ids
        attr_reader :references
        attr_reader :pendings

        attr_accessor :funnels

        attr_accessor :permanent

        def initialize(n, p = false)
            @name = n
            @permanent = p
            @messages = {}
            @message_ids = []
            @references = {}
            @pendings = {}
            @funnels = {}
            @uuid = UUID.new
        end

        def put_message(message)
            message_id = @uuid.generate
            #message[:__id] = message_id
            #message[:__sent] = Time.now.iso8601

            # If permantent bucket, then store
            Permanent.store message,"#{message_id}.dat", { :gzip => true } unless !@permanent

            @messages[message_id] = message
            @message_ids.push(message_id)
            @references[message_id] = @funnels.keys
            @pendings[message_id] = []

            if !@funnels.empty?
                # Put message in each funnel
                @funnels.each do |n,funnel|
                    $LOG.debug("Bucket #{@name} - Notifying funnel #{funnel.name}")
                    funnel.notify(self)
                end
            end
        end

        def dequeue(funnel)
            if !@messages.empty?
                message_id = nil

                @message_ids.each do |mid|
                    $LOG.debug("Bucket #{@name} - #{mid} references: #{@references[mid]}")
                    if @references[mid].count(funnel.name) > 0
                        # That message was not de-referenced yet
                        $LOG.debug("Bucket #{@name} - #{mid} -> #{funnel.name}")
                        message_id = mid
                        break
                    end
                end

                if nil != message_id
                    $LOG.debug("Bucket #{@name} - Sending #{message_id} to funnel #{funnel.name}")
                    message = @messages[message_id]

                    # Remove the given funnel from a reference
                    @references[message_id].delete(funnel.name)
                    # Add the given funnel to the pending list for that message
                    @pendings[message_id].push(funnel.name)

                    [message, message_id]
                else
                    $LOG.debug("Bucket #{@name} - No more messages for funnel #{funnel.name}")
                    [nil, nil]
                end
            else
                [nil, nil]
            end
        end

        def message_sent(funnel, message_id)
            $LOG.debug("Bucket #{@name} - Message #{message_id} sent on #{funnel.name}")
            @pendings[message_id].delete(funnel.name)

            # If no funnels are either pending or referenced, then message can be removed
            if @pendings[message_id].empty? && @references[message_id].empty?
                $LOG.debug("Bucket #{@name} - Purge message #{message_id}")
                # No more references, message can be deleted
                Permanent.remove "#{message_id}.dat" unless !@permanent
                @messages.delete(message_id)
                @message_ids.delete(message_id)
                @references.delete(message_id)
                @pendings.delete(message_id)
                true
            end

            false
        end

        def funnel(name, broadcaster = false)
            funnel = @funnels[name]
            if nil == funnel
                $LOG.info("Bucket #{@name} - Creating funnel #{name}")
                funnel = Funnel.new(name, broadcaster)
                feed_funnel(funnel)
            end
            # Update potential settings
            funnel.broadcaster = broadcaster

            funnel
        end

        def feed_funnel(funnel)
            @funnels[funnel.name] = funnel
            # Add ourself to the list of buckets for that funnel
            if funnel.buckets.count self == 0
                funnel.buckets.push(self)
            end

            # If we have cached messages, notify new funnel
            if !@messages.empty?
                # Add the current funnels as a reference
                @message_ids.each do |mid|
                    @references[mid].push(funnel.name)
                end
                $LOG.debug("Bucket #{@name} - Notifying funnel #{funnel.name}")
                funnel.notify(self)
            end

        end

    end
end


