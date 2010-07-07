class AircraftManufacturer < ActiveRecord::Base
  set_primary_key :name
  
  has_many :aircraft, :foreign_key => 'manufacturer_name'
end
