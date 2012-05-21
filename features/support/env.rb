require 'bundler'
Bundler.setup

require 'cucumber'
require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support

require 'sniff'
Sniff.init File.join(File.dirname(__FILE__), '..', '..'), :earth => [:air, :locality, :fuel], :cucumber => true, :logger => 'log/test_log.txt'

# Set up fuzzy matching between Aircraft and FlightSegment for testing
# Also, derive characteristics of Aircraft from flight_segments and deriving missing values from other aircraft in same aircraft class
require 'fuzzy_match'
require 'earth/air/flight_segment/data_miner'
require 'earth/air/aircraft/data_miner'
FlightSegment.data_miner_script.steps.clear
Aircraft.update_averages!
