module BrighterPlanet
  module Flight
    extend self

    def included(base)
      require 'flight/carbon_model'
      require 'flight/characterization'
      require 'flight/data'
      require 'flight/summarization'

      base.send :include, BrighterPlanet::Flight::CarbonModel
      base.send :include, BrighterPlanet::Flight::Characterization
      base.send :include, BrighterPlanet::Flight::Data
      base.send :include, BrighterPlanet::Flight::Summarization
    end
    def flight_model
      if Object.const_defined? 'Flight'
        ::Flight
      elsif Object.const_defined? 'FlightRecord'
        FlightRecord
      else
        raise 'There is no flight model'
      end
    end
  end
end
