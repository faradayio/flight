require 'bundler/setup'

require 'sniff'
Sniff.init File.join(File.dirname(__FILE__), '..', '..'),
  :cucumber => true,
  :logger => false # change this to $stderr to see database activity

# Set up fuzzy matching between Aircraft and FlightSegment for testing
# Also, derive characteristics of Aircraft from flight_segments and deriving missing values from other aircraft in same aircraft class
require 'fuzzy_match'
FlightSegment.data_miner_script.steps.clear
Aircraft.update_averages!

require 'geocoder'
class GeocoderWrapper
  def distance_between(origin, destination)
    Geocoder::Calculations.distance_between origin.values_at(:latitude, :longitude), destination.values_at(:latitude, :longitude), :units => :km
  end
end
BrighterPlanet::Flight.geocoder = GeocoderWrapper.new
