require 'characterizable'

module BrighterPlanet
  module Flight
    module Characterization
      def self.included(base)
        base.send :include, Characterizable
        base.characterize do
          has :aviation_multiplier
          has :distance_estimate, :trumps => :distance_class, :measures => :length, :precision => 0
          has :distance_class
          has :fuel_type
          has :seats_estimate, :range => 1..500
          has :load_factor, :measures => :percentage
          has :trips
          has :seat_class
          has :country
          has :date
          has :origin_airport do |origin_airport|
            origin_airport.reveals :destination_airport, 
              :trumps => [:distance_class, :distance_estimate, :country]
          end
          has :aircraft, :trumps => [:aircraft_class, :seats_estimate, :fuel_type]
          has :aircraft_class, :trumps => :fuel_type
          has :airline
          has :segments_per_trip
        end
      end
    end
  end
end
