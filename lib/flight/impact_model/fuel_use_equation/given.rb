module BrighterPlanet
  module Flight
    module ImpactModel
      class FuelUseEquation
        class Given < FuelUseEquation
          attr_reader :m3, :m2, :m1, :b
          def initialize(m3, m2, m1, b)
            @m3 = m3
            @m2 = m2
            @m1 = m1
            @b = b
          end
        end
      end
    end
  end
end
