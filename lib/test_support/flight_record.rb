require 'active_record'
require 'falls_back_on'
require 'flight'
require 'sniff'

class FlightRecord < ActiveRecord::Base
  include Sniff::Emitter
  include BrighterPlanet::Flight
  set_table_name 'flight_records'

  falls_back_on :trips => 1.941, # http://www.bts.gov/publications/america_on_the_go/long_distance_transportation_patterns/html/table_07.html
                :emplanements_per_trip => 1.67,
                :distance_estimate => 2077.4455,
                :load_factor => lambda { FlightSegment.fallback.load_factor }
end
