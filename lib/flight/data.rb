require 'data_miner'

module BrighterPlanet
  module Flight
    module Data
      def self.included(base)
        base.data_miner do
          schema do
            float   'aviation_multiplier'
            float   'distance_estimate'
            string  'distance_class_name'
            string  'fuel_type_name'
            integer 'seats_estimate'
            float   'load_factor'
            integer 'trips'
            string  'seat_class_name'
            string  'country_iso_3166_code'
            date    'date'
            string  'origin_airport_iata_code'
            string  'destination_airport_iata_code'
            string  'aircraft_bp_code'
            string  'aircraft_class_code'
            string  'airline_iata_code'
            integer 'segments_per_trip'
          end
          
          process :run_data_miner_on_belongs_to_associations
        end
      end
    end
  end
end
