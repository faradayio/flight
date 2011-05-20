module BrighterPlanet
  module Flight
    module Relationships
      def self.included(target)
        target.belongs_to :distance_class,      :class_name => 'FlightDistanceClass', :foreign_key => 'distance_class_name'
        target.belongs_to :fuel,                                                      :foreign_key => 'fuel_name'
        target.belongs_to :origin_airport,      :class_name => 'Airport',             :foreign_key => 'origin_airport_iata_code'
        target.belongs_to :destination_airport, :class_name => 'Airport',             :foreign_key => 'destination_airport_iata_code'
        target.belongs_to :aircraft,                                                  :foreign_key => 'aircraft_icao_code'
        target.belongs_to :airline,                                                   :foreign_key => 'airline_name'
      end
    end
  end
end
