require 'flight'

class FlightRecord < Sniff::Emitter
  include BrighterPlanet::Flight

  attr_accessor :fuel, :passengers, :seat_class_multiplier, 
    :emission_factor, :radiative_forcing_index, :freight_share, :date,
    :fuel_per_segment, :emplanements_per_trip, :trips, :origin_airport,
    :destination_airport, :airline
end
