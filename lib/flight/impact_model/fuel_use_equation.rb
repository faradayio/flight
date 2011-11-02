module BrighterPlanet
  module Flight
    module ImpactModel
      class FuelUseEquation < ::Struct.new(:m3, :m2, :m1, :b)
        class << self
          def new_if_valid(*args)
            if (equation = new(*args)).valid?
              equation
            end
          end
        end
        
        def values
          [m3, m2, m1, b]
        end
        
        def valid?
          values.all?(&:present?) and values.any?(&:nonzero?)
        end
      end
    end
  end
end
