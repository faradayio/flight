module BrighterPlanet
  module Flight
    module ImpactModel
      class FuelUseEquation < Struct.new(:m3, :m2, :m1, :b)
        def values
          [m3, m2, m1, b]
        end
        
        def valid?
          values.all?(&:present?) and values.any?(&:nonzero?)
        end
        
        def to_xml(options = {})
          options[:indent] ||= 2
          xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
          xml.instruct! unless options[:skip_instruct]
          xml.fuel_use_equation do |estimate_block|
            estimate_block.b b, :type => 'float'
            estimate_block.m1 m1, :type => 'float'
            estimate_block.m2 m2, :type => 'float'
            estimate_block.m3 m3, :type => 'float'
          end
        end
      end
    end
  end
end