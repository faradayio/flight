module BrighterPlanet
  module Flight
    module Characterization
      def self.included(base)
        base.characterize do
          has :date, :trumps => :year
          has :year
          has :time_of_day
          has :origin_airport do |origin_airport|
            origin_airport.reveals :destination_airport, 
              :trumps => [:distance_class, :domesticity, :distance_estimate]
          end
          has :distance_class
          has :distance_estimate, :trumps => :distance_class, :measures => :length, :precision => 0
          has :domesticity
          has :airline
          has :trips
          has :emplanements_per_trip
          has :seat_class
          has :load_factor, :measures => :percentage
          has :seats_estimate, :range => 1..500
          has :aircraft_class, :trumps => [:propulsion, :fuel_type]
          has :aircraft, :trumps => [:propulsion, :aircraft_class, :seats_estimate, :fuel_type]
          has :propulsion, :trumps => :fuel_type

          has :creation_date, :hidden => true
        end
      end
    end
  end
end
