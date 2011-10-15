require File.expand_path('../lib/tinyq/version', __FILE__)

Gem::Specification.new do |spec|
    spec.name = 'tinyq'
    spec.version = TinyQ::VERSION
    spec.authors = ["Jerome Poichet"]
    spec.email = ["poitch@gmail.com"]
    spec.homepage = "https://github.com/poitch/TinyQ"
    spec.summary = 'Ruby/TinyQ'
    spec.description = 'TinyQ is a message broker with a simple JSON based protocol'

    spec.files = ["lib/tinyq.rb", "lib/tinyq/bucket.rb", "lib/tinyq/client.rb", "lib/tinyq/connection.rb", "lib/tinyq/defs.rb", "lib/tinyq/funnel.rb", "lib/tinyq/journal.rb", "lib/tinyq/permanent.rb", "lib/tinyq/server.rb", "lib/tinyq/subscriber.rb", "lib/tinyq/version.rb"]

    spec.bindir = "bin"
    spec.require_paths << "lib"
    spec.executables = ["tinyq"]

    spec.add_dependency "eventmachine"
    spec.add_dependency "json"
    spec.add_dependency "uuid"
    spec.add_dependency "getopt"
    spec.add_dependency "daemons"

end
