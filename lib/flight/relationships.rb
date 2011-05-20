module BrighterPlanet
  module Flight
    module Relationships
      def self.included(target)
        target.belongs_to :origin_airport,      :foreign_key => 'origin_airport_iata_code',      :class_name => 'Airport'
        target.belongs_to :destination_airport, :foreign_key => 'destination_airport_iata_code', :class_name => 'Airport'
        target.belongs_to :aircraft,            :foreign_key => 'aircraft_icao_code'
        target.belongs_to :airline,             :foreign_key => 'airline_name'
        target.belongs_to :fuel,                :foreign_key => 'fuel_name'
        target.belongs_to :distance_class,      :foreign_key => 'distance_class_name',           :class_name => 'FlightDistanceClass'
      end
    end
  end
end
