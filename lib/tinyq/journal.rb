module TinyQ
    class Journal
        include Singleton

        attr_accessor :enabled

        def initialize
            @journal = File.open("journal.txt", "a")
            @enabled = false
        end

        def event(event)
            if @enabled
                now=Time.now.iso8601
                @journal.puts("#{now},#{event[:Event]}")
                @journal.fsync
            end
        end

    end
end
