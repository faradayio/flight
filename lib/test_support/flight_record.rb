require 'active_record'
require 'falls_back_on'
require 'flight'
require 'sniff'

class FlightRecord < ActiveRecord::Base
  include Sniff::Emitter
  include BrighterPlanet::Flight
  set_table_name 'flight_records'

  belongs_to :origin_airport, :class_name => 'Airport'
  belongs_to :destination_airport, :class_name => 'Airport'
  belongs_to :distance_class, :class_name => 'FlightDistanceClass'
  belongs_to :fuel_type, :class_name => 'FlightFuelType'
  belongs_to :propulsion, :class_name => 'FlightPropulsion'
  belongs_to :aircraft_class
  belongs_to :aircraft
  belongs_to :seat_class, :class_name => 'FlightSeatClass'
  belongs_to :airline
  belongs_to :domesticity, :class_name => 'FlightDomesticity'
  
  falls_back_on :trips => 1.941, # http://www.bts.gov/publications/america_on_the_go/long_distance_transportation_patterns/html/table_07.html
                :emplanements_per_trip => 1.67,
                :distance_estimate => 2077.4455,
                :load_factor => lambda { FlightSegment.fallback.load_factor }

  class << self
    def research(key)
      case key
      when :route_inefficiency_factor
        1.07
      when :dogleg_factor
        1.25
      end
    end
  end
end
