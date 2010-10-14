require 'leap'
require 'timeframe'
require 'date'
require 'weighted_average'

module BrighterPlanet
  module Flight
    module CarbonModel
      def self.included(base)
        base.extend FastTimestamp
        base.decide :emission, :with => :characteristics do
          committee :emission do
            quorum 'from fuel and passengers with coefficients', 
              :needs => [:fuel, :passengers, :seat_class_multiplier, :emission_factor, 
                         :radiative_forcing_index, :freight_share] do |characteristics|
              #( kg fuel ) * ( kg CO2 / kg fuel ) = kg CO2
              (characteristics[:fuel] / characteristics[:passengers] * characteristics[:seat_class_multiplier]) * characteristics[:emission_factor] * characteristics[:radiative_forcing_index] * (1 - characteristics[:freight_share])
            end
            
            quorum 'default' do
              raise "The emission committee's default quorum should never be called"
            end
          end
          
          committee :emission_factor do # returns kg CO2 / kg fuel
            quorum 'from fuel type', :needs => :fuel_type do |characteristics|
              #(            kg CO2 / litres fuel        ) * (                 litres fuel / kg fuel                      )
              characteristics[:fuel_type].emission_factor * ( 1 / characteristics[:fuel_type].density).gallons.to(:litres)
            end
          end
          
          committee :radiative_forcing_index do
            quorum 'from fuel type', :needs => :fuel_type do |characteristics|
              characteristics[:fuel_type].radiative_forcing_index
            end
          end
          committee :fuel do # returns kg fuel
            quorum 'from fuel per segment and emplanements and trips', :needs => [:fuel_per_segment, :emplanements_per_trip, :trips] do |characteristics|
              characteristics[:fuel_per_segment] * characteristics[:emplanements_per_trip].to_f * characteristics[:trips].to_f
            end
          end
          
          committee :fuel_per_segment do # returns kg fuel
            quorum 'from adjusted distance per segment and fuel use coefficients', :needs => [:adjusted_distance_per_segment, :fuel_use_coefficients] do |characteristics|
              characteristics[:fuel_use_coefficients].m3.to_f * characteristics[:adjusted_distance_per_segment].to_f ** 3 +
                characteristics[:fuel_use_coefficients].m2.to_f * characteristics[:adjusted_distance_per_segment].to_f ** 2 +
                characteristics[:fuel_use_coefficients].m1.to_f * characteristics[:adjusted_distance_per_segment].to_f +
                characteristics[:fuel_use_coefficients].endpoint_fuel.to_f
            end
          end
          
          committee :adjusted_distance_per_segment do
            quorum 'from adjusted distance and emplanements', :needs => [:adjusted_distance, :emplanements_per_trip] do |characteristics|
              characteristics[:adjusted_distance] / characteristics[:emplanements_per_trip]
            end
          end
          
          committee :adjusted_distance do # returns nautical miles
            quorum 'from distance', :needs => [:distance, :emplanements_per_trip] do |characteristics|
              route_inefficiency_factor = base.research(:route_inefficiency_factor)
              dogleg_factor = base.research(:dogleg_factor)
              characteristics[:distance] * route_inefficiency_factor * ( dogleg_factor ** (characteristics[:emplanements_per_trip] - 1) )
            end
          end
          
          committee :distance do # returns nautical miles
            quorum 'from airports', :needs => [:origin_airport, :destination_airport] do |characteristics|
              if  characteristics[:origin_airport].latitude and
                  characteristics[:origin_airport].longitude and
                  characteristics[:destination_airport].latitude and
                  characteristics[:destination_airport].longitude
                characteristics[:origin_airport].distance_to(characteristics[:destination_airport], :units => :kms).kilometres.to :nautical_miles
              end
            end
            
            quorum 'from distance estimate', :needs => :distance_estimate do |characteristics|
              characteristics[:distance_estimate].kilometres.to :nautical_miles
            end
            
            quorum 'from distance class', :needs => :distance_class do |characteristics|
              characteristics[:distance_class].distance.kilometres.to :nautical_miles
            end
            
            quorum 'from cohort', :needs => :cohort do |characteristics|
              distance = characteristics[:cohort].weighted_average(:distance, :weighted_by => :passengers).to_f.kilometres.to(:nautical_miles)
              distance > 0 ? distance : nil
            end
            
            quorum 'default' do
              base.fallback.distance_estimate.kilometres.to :nautical_miles
            end
          end
          
          committee :fuel_use_coefficients do
            quorum 'from aircraft', :needs => :aircraft do |characteristics|
              aircraft = characteristics[:aircraft]
              FuelUseEquation.new aircraft.m3, aircraft.m2, aircraft.m1, aircraft.endpoint_fuel
            end
            
            quorum 'from aircraft class', :needs => :aircraft_class do |characteristics|
              aircraft_class = characteristics[:aircraft_class]
              FuelUseEquation.new aircraft_class.m3, aircraft_class.m2, aircraft_class.m1, aircraft_class.endpoint_fuel
            end
            
            quorum 'from cohort', :needs => :cohort do |characteristics|
              flight_segments = characteristics[:cohort]
              
              passengers = flight_segments.inject(0) do |passengers, flight_segment|
                passengers + flight_segment.passengers
              end

              flight_segment_aircraft = flight_segments.inject({}) do |hsh, flight_segment|
                bts_code = flight_segment.bts_aircraft_type_code
                key = flight_segment.row_hash
                aircraft = Aircraft.find_by_bts_aircraft_type_code bts_code
                hsh[key] = aircraft if aircraft
                hsh
              end
              
              if flight_segment_aircraft.values.map(&:m3).any?
                m3 = flight_segments.inject(0) do |m3, flight_segment|
                  aircraft = flight_segment_aircraft[flight_segment.row_hash]
                  aircraft_m3 = aircraft.andand.m3 || 0
                  m3 + (aircraft_m3 * flight_segment.passengers)
                end
              else
                m3 = Aircraft.fallback.m3
              end
              
              if flight_segment_aircraft.values.map(&:m2).any?
                m2 = flight_segments.inject(0) do |m2, flight_segment|
                  aircraft = flight_segment_aircraft[flight_segment.row_hash]
                  aircraft_m2 = aircraft.andand.m2 || 0
                  m2 + (aircraft_m2 * flight_segment.passengers)
                end
              else
                m2 = Aircraft.fallback.m2
              end

              if flight_segment_aircraft.values.map(&:m1).any?
                m1 = flight_segments.inject(0) do |m1, flight_segment|
                  aircraft = flight_segment_aircraft[flight_segment.row_hash]
                  aircraft_m1 = aircraft.andand.m1 || 0
                  m1 + (aircraft_m1 * flight_segment.passengers)
                end
              else
                m1 = Aircraft.fallback.m1
              end

              if flight_segment_aircraft.values.map(&:endpoint_fuel).any?
                endpoint_fuel = flight_segments.inject(0) do |endpoint_fuel, flight_segment|
                  aircraft = flight_segment_aircraft[flight_segment.row_hash]
                  aircraft_epfuel = aircraft.andand.endpoint_fuel || 0
                  endpoint_fuel + (aircraft_epfuel * flight_segment.passengers)
                end
              else
                endpoint_fuel = Aircraft.fallback.endpoint_fuel
              end

              if [m3, m2, m1, endpoint_fuel, passengers].any?(&:nonzero?)
                m3 = m3 / passengers
                m2 = m2 / passengers
                m1 = m1 / passengers
                endpoint_fuel = endpoint_fuel / passengers

                FuelUseEquation.new m3, m2, m1, endpoint_fuel
              end
            end
            
            quorum 'default' do
              fallback = Aircraft.fallback
              if fallback
                FuelUseEquation.new fallback.m3, fallback.m2, fallback.m1, fallback.endpoint_fuel
              end
            end
          end
          
          committee :fuel_type do
            quorum 'default' do
              FlightFuelType.fallback
            end
          end
          
          committee :passengers do
            quorum 'from seats and load factor', :needs => [:seats, :load_factor] do |characteristics|
              (characteristics[:seats] * characteristics[:load_factor]).round
            end
          end
          
          committee :seats do
            
            quorum 'from aircraft', :needs => :aircraft do |characteristics|
              characteristics[:aircraft].seats
            end
            
            quorum 'from seats estimate', :needs => :seats_estimate do |characteristics|
              characteristics[:seats_estimate]
            end
            
            quorum 'from cohort', :needs => :cohort do |characteristics|
              seats = characteristics[:cohort].weighted_average :seats, :weighted_by => :passengers
              if seats.nil? or seats.zero?
                nil
              else
                seats
              end
            end
            
            quorum 'from aircraft class', :needs => :aircraft_class do |characteristics|
              characteristics[:aircraft_class].seats_before_type_cast
            end
            
            quorum 'default' do
              FlightSegment.fallback.andand.seats
            end
          end
          
          committee :load_factor do
            quorum 'from cohort', :needs => :cohort do |characteristics|
              characteristics[:cohort].weighted_average(:load_factor, :weighted_by => :passengers)
            end
      
            quorum 'default' do
              base.fallback.andand.load_factor
            end
          end
          
          committee :freight_share do
            quorum 'from cohort', :needs => :cohort do |characteristics|
              characteristics[:cohort].weighted_average(:freight_share, :weighted_by => :passengers)
            end
            
            quorum 'default' do
              FlightSegment.fallback.freight_share
            end
          end
          
          committee :trips do
            quorum 'default' do
              base.fallback.andand.trips_before_type_cast
            end
          end
          
          committee :seat_class_multiplier do
            quorum 'from seat class', :needs => :seat_class do |characteristics|
              characteristics[:seat_class].multiplier
            end
            
            quorum 'default' do
              FlightSeatClass.fallback.multiplier
            end
          end
          
          committee :cohort do
            quorum 'from t100', :appreciates => [:origin_airport, :destination_airport, :aircraft, :airline] do |characteristics|
              provided_characteristics = [:origin_airport, :destination_airport, :aircraft, :airline].
                inject(ActiveSupport::OrderedHash.new) do |memo, characteristic_name|
                  memo[characteristic_name] = characteristics[characteristic_name]
                  memo
                end
              cohort = FlightSegment.strict_cohort provided_characteristics
              if cohort.any?
                cohort
              else
                nil
              end
            end
          end
          
          committee :emplanements_per_trip do # per trip
            quorum 'default' do
              base.fallback.emplanements_per_trip_before_type_cast
            end
          end
        end
      end
      
      class FuelUseEquation < Struct.new(:m3, :m2, :m1, :endpoint_fuel); end
    end
  end
end
