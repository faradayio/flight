require 'bundler'
Bundler.setup

require 'cucumber'
require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support

require 'sniff'
Sniff.init File.join(File.dirname(__FILE__), '..', '..'), :earth => [:air, :locality, :fuel], :cucumber => true, :logger => 'log/test_log.txt'

# Set up fuzzy matching between Aircraft and FlightSegment for testing
require 'loose_tight_dictionary'
require 'earth/air/flight_segment/data_miner'
step = FlightSegment.data_miner_config.steps.detect { |s| s.class == DataMiner::Process and s.block_description =~ /cache fuzzy/i }
step.run
