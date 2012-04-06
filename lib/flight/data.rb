module BrighterPlanet
  module Flight
    module Data
      def self.included(base)
        base.col :date, :type => :date
        base.col :segments_per_trip, :type => :integer
        base.col :origin_airport_iata_code
        base.col :destination_airport_iata_code
        base.col :aircraft_icao_code
        base.col :airline_name
        base.col :trips, :type => :integer
        base.col :load_factor, :type => :float
        base.col :seats, :type => :integer
        base.col :fuel_name
        base.col :distance_estimate, :type => :float
        base.col :distance_class_name
        base.col :seat_class_name
        base.col :flight_segment_row_hash
        
        base.data_miner do
          process "pull orphans" do
            FlightSeatClass.run_data_miner!
            FlightSegment.run_data_miner!
          end
        end
      end
    end
  end
end
