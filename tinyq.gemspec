require File.expand_path('../lib/tinyq/version', __FILE__)

Gem::Specification.new do |s|
    s.name = 'tinyq'
    s.version = TinyQ::VERSION
    s.authors = ["Jerome Poichet"]
    s.email = ["poitch@gmail.com"]

    s.files = ["bin/tinyq", "lib/tinyq.rb", "lib/tinyq/bucket.rb", "lib/tinyq/connection.rb", "lib/tinyq/funnel.rb", "lib/tinyq/permanent.rb", "lib/tinyq/server.rb", "lib/tinyq/subscriber.rb", "lib/tinyq/version.rb"]

    s.summary = 'Ruby/TinyQ'
    s.description = 'TinyQ is a message broker with a simple JSON based protocol'
end
