require 'active_record'
require 'falls_back_on'
require 'flight'
require 'sniff'

class FlightRecord < ActiveRecord::Base
  include Sniff::Emitter
  include BrighterPlanet::Flight
  set_table_name 'flight_records'

  falls_back_on :aviation_multiplier       => 2.0,       # from Kolmuss and Crimmins (2009) http://sei-us.org/publications/id/13
                :dogleg_factor             => 1.25,      # assumed
                :trips                     => 1.941,     # http://www.bts.gov/publications/america_on_the_go/long_distance_transportation_patterns/html/table_07.html
                :segments_per_trip         => 1.67       # calculated from http://nhts.ornl.gov/
end
