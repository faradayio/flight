require 'flight'

class FlightRecord < ActiveRecord::Base
  include Sniff::Emitter
  include BrighterPlanet::Flight
  set_table_name 'flights'

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
  
  # has_many :flight_patterns
  
  falls_back_on :trips => 1.941, # http://www.bts.gov/publications/america_on_the_go/long_distance_transportation_patterns/html/table_07.html
                :emplanements_per_trip => 1.67, # https://brighterplanet.sifterapp.com/projects/30/issues/348
                :distance_estimate => 2077.4455, # SELECT SUM(passengers * distance) / SUM(passengers) FROM flight_segments;
                :load_factor => lambda { FlightSegment.fallback.load_factor }

  data_miner do
    schema do
      string   'origin_airport_id'
      string   'destination_airport_id'
      integer  'trips'
      integer  'emplanements_per_trip'
      float    'distance_estimate'
      string   'distance_class_id'
      string   'aircraft_id'
      string   'aircraft_class_id'
      string   'propulsion_id'
      string   'fuel_type_id'
      string   'airline_id'
      string   'seat_class_id'
      integer  'seats_estimate'
      float    'load_factor'
      string   'domesticity_id'
      date     'date'
      integer  'year'
      time     'time_of_day'
    end
    
    process "pull dependencies" do
      run_data_miner_on_belongs_to_associations
    end
  end
  
  characterize do
    has :date, :trumps => :year
    has :year
    has :time_of_day
    has :origin_airport do |origin_airport|
      origin_airport.reveals :destination_airport, :trumps => [:distance_class, :domesticity, :distance_estimate]
    end
    has :distance_class
    has :distance_estimate, :trumps => :distance_class, :measures => :length, :precision => 0
    has :domesticity
    has :airline
    has :trips
    has :emplanements_per_trip
    has :seat_class
    has :load_factor, :measures => :percentage
    has :seats_estimate, :range => 1..500
    has :aircraft_class, :trumps => [:propulsion, :fuel_type]
    has :aircraft, :trumps => [:propulsion, :aircraft_class, :seats_estimate, :fuel_type]
    has :propulsion, :trumps => :fuel_type

    has :creation_date, :hidden => true
  end
  
  class << self
    
    def research(key)
      case key
      when :route_inefficiency_factor
        1.07 # https://brighterplanet.sifterapp.com/projects/30/issues/467
      when :dogleg_factor
        1.25 # https://brighterplanet.sifterapp.com/projects/30/issues/467
      end
    end
    
  end
  
  def creation_date
    created_at.to_date if created_at
  end
  
  def emission_date
    date || committee_reports[:date]
  end
  
  def vehicle
    if aircraft
      aircraft.name
    elsif aircraft_class
      aircraft_class.name
    end
  end
end
