require 'data_miner'

module BrighterPlanet
  module Flight
    module Data
      def self.included(base)
        base.data_miner do
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
            date     'date'
            integer  'year'
            time     'time_of_day'
          end
          
          process "pull orphans" do
            FlightSegment.run_data_miner!
          end
          
          process :run_data_miner_on_belongs_to_associations
        end
      end
    end
  end
end
