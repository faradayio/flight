require 'spec_helper'
require 'flight/carbon_model'

describe BrighterPlanet::Flight::CarbonModel do

  describe BrighterPlanet::Flight::CarbonModel::FuelUseEquation do
    describe '#to_xml' do
      it 'should generate xml' do
        eq = BrighterPlanet::Flight::CarbonModel::FuelUseEquation.new(
          0.01, 0.783, 0.575, 2.762
        )

        eq.to_xml.should == <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<fuel_use_equation>
  <b type="float">2.762</b>
  <m1 type="float">0.575</m1>
  <m2 type="float">0.783</m2>
  <m3 type="float">0.01</m3>
</fuel_use_equation>
        XML
      end
    end
  end
end
