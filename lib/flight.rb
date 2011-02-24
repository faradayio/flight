require 'emitter'

module BrighterPlanet
  module Flight
    extend BrighterPlanet::Emitter
    scope 'The flight emission estimate is the anthropogenic emissions per passenger from aircraft fuel combustion and radiative forcing. It includes CO2 emissions from combustion of non-biogenic fuel and extra forcing effects of high-altitude combustion.'
  end
end
