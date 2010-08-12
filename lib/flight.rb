require 'emitter'

module BrighterPlanet
  module Flight
    extend BrighterPlanet::Emitter

    def self.flight_model
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
