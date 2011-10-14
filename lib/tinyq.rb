# Install
# gem install eventmachine json uuid
# 
#
# TODO
#   capped - for bucket and funnel
#       - overflow or round-robin
#
#   permanent - for bucket and funnel
#   stream - for GetMessages 
#   (basically if count = 0 then send 1 message at a time, but never remove subscriber

require 'rubygems'
require 'eventmachine'
require 'json'
require 'logger'
require 'time'
require 'uuid'
require 'getopt/std'
require 'singleton'
require 'daemons'

require 'tinyq/subscriber'
require 'tinyq/funnel'
require 'tinyq/bucket'
require 'tinyq/server'
require 'tinyq/connection'
require 'tinyq/permanent'
require 'tinyq/client'
require 'tinyq/version'
require 'tinyq/defs'
require 'tinyq/journal'


$LOG = Logger.new(STDOUT)
$LOG.level = Logger::INFO

