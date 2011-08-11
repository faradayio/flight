require 'bundler'
Bundler.setup

require 'cucumber'
require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support

require 'sniff'
Sniff.init File.join(File.dirname(__FILE__), '..', '..'), :earth => [:air, :locality, :fuel], :cucumber => true, :logger => 'log/test_log.txt'

# Set up fuzzy matching between Aircraft and FlightSegment and derive Aircraft seats and passengers from FlightSegment
require 'loose_tight_dictionary'
require 'earth/air/flight_segment/data_miner'
require 'earth/air/aircraft/data_miner'
FlightSegment.data_miner_config.steps.clear
Aircraft.update_averages!

# Derive AircraftClass fuel use equations and seats from Aircraft
require 'earth/air/aircraft_class/data_miner'
Aircraft.data_miner_config.steps.clear
AircraftClass.run_data_miner!
