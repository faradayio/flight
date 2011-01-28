module BrighterPlanet
  module Flight
    module Relationships
      def self.included(target)
        target.belongs_to :distance_class,      :class_name => 'FlightDistanceClass', :foreign_key => 'distance_class_name'
        target.belongs_to :fuel_type,                                                 :foreign_key => 'fuel_type_name'
        target.belongs_to :country,                                                   :foreign_key => 'country_iso_3166_code'
        target.belongs_to :origin_airport,      :class_name => 'Airport',             :foreign_key => 'origin_airport_iata_code'
        target.belongs_to :destination_airport, :class_name => 'Airport',             :foreign_key => 'destination_airport_iata_code'
        target.belongs_to :aircraft,                                                  :foreign_key => 'aircraft_bp_code'
        target.belongs_to :aircraft_class,                                            :foreign_key => 'aircraft_class_code'
        target.belongs_to :airline,                                                   :foreign_key => 'airline_iata_code'
      end
    end
  end
end
