require 'flight/impact_model/fuel_use_equation/derived'
require 'flight/impact_model/fuel_use_equation/given'

module BrighterPlanet
  module Flight
    module ImpactModel
      class FuelUseEquation
        class << self
          def from_coefficients(m3, m2, m1, b)
            equation = Given.new(m3, m2, m1, b)
            if equation.valid?
              equation
            else
              nil
            end
          end

          def from_flight_segments(flight_segments)
            equation = Derived.new flight_segments
            if equation.valid?
              equation
            else
              nil
            end
          end
        end

        def valid?
          coefficients.all?(&:present?) and coefficients.any?(&:nonzero?)
        end

        def coefficients
          [ m3, m2, m1, b ]
        end
      end
    end
  end
end
