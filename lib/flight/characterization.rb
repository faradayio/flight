module BrighterPlanet
  module Flight
    module Characterization
      def self.included(base)
        base.characterize do
          has :date
          has :segments_per_trip
          has :origin_airport
          has :destination_airport
          has :aircraft
          has :airline
          has :trips
          has :load_factor
          has :seats_estimate
          has :fuel
          has :distance_estimate
          has :distance_class
          has :seat_class_name
        end
      end
    end
  end
end
