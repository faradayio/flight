module BrighterPlanet
  module Flight
    module Relationships
      def self.included(target)
        target.belongs_to :distance_class,      :class_name => 'FlightDistanceClass', :foreign_key => 'name'
        target.belongs_to :fuel_type,                                                 :foreign_key => 'name'
        target.belongs_to :seat_class,          :class_name => 'FlightSeatClass',     :foreign_key => 'name'
        target.belongs_to :country,                                                   :foreign_key => 'iso_3166_code'
        target.belongs_to :origin_airport,      :class_name => 'Airport',             :foreign_key => 'iata_code'
        target.belongs_to :destination_airport, :class_name => 'Airport',             :foreign_key => 'iata_code'
        target.belongs_to :aircraft,                                                  :foreign_key => 'icao_code'
        target.belongs_to :aircraft_class,                                            :foreign_key => 'brighter_planet_aircraft_class_code'
        target.belongs_to :airline,                                                   :foreign_key => 'iata_code'
      end
    end
  end
end
