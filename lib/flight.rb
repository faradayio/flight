require 'flight/decisions'
require 'flight/characterization'
require 'flight/data_miner'
require 'flight/summarization'

module BrighterPlanet
  module Flight
    extend self

    def included(base)
      base.send :include, BrighterPlanet::Flight::Decisions
      base.send :include, BrighterPlanet::Flight::Characterization
#      base.send :include, BrighterPlanet::Flight::DataMiner
      base.send :include, BrighterPlanet::Flight::Summarization
    end
    def flight_model
      if Object.const_defined? 'Flight'
        Flight
      elsif Object.const_defined? 'FlightRecord'
        FlightRecord
      else
        raise 'There is no flight model'
      end
    end
  end
end
