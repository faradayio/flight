require 'emitter'

module BrighterPlanet
  module Flight
    extend BrighterPlanet::Emitter
    # FIXME TODO each impact should have it's own scope; this is the scope of the greenhouse gas emission (carbon) impact
    scope 'The flight greenhouse gas emission is the anthropogenic greenhouse gas emissions attributed to a single passenger on this flight. It includes CO2 emissions from combustion of non-biogenic fuel and extra forcing effects of high-altitude fuel combustion.'
  end
end
