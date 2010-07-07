class AircraftClass < ActiveRecord::Base
  set_primary_key :brighter_planet_aircraft_class_code
  
  has_many :aircraft, :foreign_key => 'brighter_planet_aircraft_class_code'
#  has_many :airline_aircraft_seat_classes, :through => :aircraft
end
