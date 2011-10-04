require 'active_record'
require 'falls_back_on'
require 'flight'
require 'sniff'

class FlightRecord < ActiveRecord::Base
  include BrighterPlanet::Emitter
  include BrighterPlanet::Flight
  set_table_name 'flight_records'
end
