require 'characterizable'

module BrighterPlanet
  module Flight
    module Characterization
      def self.included(base)
        base.send :include, Characterizable
        base.characterize do
          # sabshere 12/13/10 should this really be a user input?
          has :aviation_multiplier
          has :distance_estimate
          has :distance_class
          has :fuel_type
          has :seats_estimate
          has :load_factor
          has :trips
          has :seat_class
          has :country
          has :date
          has :origin_airport
          has :destination_airport
          has :aircraft
          has :aircraft_class
          has :airline
          has :segments_per_trip
        end
      end
    end
  end
end
