# Copyright © 2010 Brighter Planet.
# See LICENSE for details.
# Contact Brighter Planet for dual-license arrangements.

require 'weighted_average'

module BrighterPlanet
  module Flight
    module CarbonModel
      def self.included(base)
        base.extend FastTimestamp
        base.decide :emission, :with => :characteristics do
          committee :emission do
            quorum 'from fuel, emission factor, freight share, passengers, multipliers, and date',
              :needs => [:fuel, :emission_factor, :freight_share, :passengers, :seat_class_multiplier, :aviation_multiplier, :date], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics, timeframe|
              date = characteristics[:date].is_a?(Date) ?
                characteristics[:date] :
                Date.parse(characteristics[:date].to_s)
              if timeframe.include? date
                characteristics[:fuel] * characteristics[:emission_factor] * characteristics[:aviation_multiplier] * (1 - characteristics[:freight_share]) / characteristics[:passengers] * characteristics[:seat_class_multiplier]
              # If the flight did not occur during the `timeframe`, `emission` is zero.
              else
                0
              end
            end
            
            quorum 'default' do
              raise "The emission committee's default quorum should never be called"
            end
          end
          
          committee :emission_factor do
            quorum 'from fuel type', :needs => :fuel_type, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:fuel_type].emission_factor / characteristics[:fuel_type].density
            end
          end
          
          committee :aviation_multiplier do
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              base.fallback.aviation_multiplier
            end
          end
          
          committee :fuel do
            quorum 'from fuel per segment and segments per trip and trips', :needs => [:fuel_per_segment, :segments_per_trip, :trips], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:fuel_per_segment] * characteristics[:segments_per_trip].to_f * characteristics[:trips].to_f
            end
          end
          
          committee :fuel_per_segment do
            quorum 'from adjusted distance per segment and fuel use coefficients', :needs => [:adjusted_distance_per_segment, :fuel_use_coefficients], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:fuel_use_coefficients].m3.to_f * characteristics[:adjusted_distance_per_segment].to_f ** 3 +
                characteristics[:fuel_use_coefficients].m2.to_f * characteristics[:adjusted_distance_per_segment].to_f ** 2 +
                characteristics[:fuel_use_coefficients].m1.to_f * characteristics[:adjusted_distance_per_segment].to_f +
                characteristics[:fuel_use_coefficients].endpoint_fuel.to_f
            end
          end
          
          committee :adjusted_distance_per_segment do
            quorum 'from adjusted distance and segments per trip', :needs => [:adjusted_distance, :segments_per_trip], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:adjusted_distance] / characteristics[:segments_per_trip]
            end
          end
          
          committee :adjusted_distance do
            quorum 'from distance, route inefficiency factor, and dogleg factor', :needs => [:distance, :route_inefficiency_factor, :dogleg_factor], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:distance] * characteristics[:route_inefficiency_factor] * characteristics[:dogleg_factor]
            end
          end
          
          committee :distance do
            quorum 'from airports', :needs => [:origin_airport, :destination_airport], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              if  characteristics[:origin_airport].latitude and
                  characteristics[:origin_airport].longitude and
                  characteristics[:destination_airport].latitude and
                  characteristics[:destination_airport].longitude
                characteristics[:origin_airport].distance_to(characteristics[:destination_airport], :units => :kms).kilometres.to :nautical_miles
              end
            end
            
            quorum 'from distance estimate', :needs => :distance_estimate, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:distance_estimate].kilometres.to :nautical_miles
            end
            
            quorum 'from distance class', :needs => :distance_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:distance_class].distance.kilometres.to :nautical_miles
            end
            
            quorum 'from cohort', :needs => :cohort do |characteristics| # cohort here will be some combo of origin, airline, and aircraft
              distance = characteristics[:cohort].weighted_average(:distance, :weighted_by => :passengers).kilometres.to(:nautical_miles)
              distance > 0 ? distance : nil
            end
            
            quorum 'default' do
              base.fallback.distance_estimate.kilometres.to :nautical_miles
            end
          end
          
          committee :route_inefficiency_factor do
            quorum 'from country', :needs => :country, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:country].flight_route_inefficiency_factor
            end
            
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              Country.fallback.flight_route_inefficiency_factor
            end
          end
          
          committee :dogleg_factor do
            quorum 'from segments per trip', :needs => :segments_per_trip, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              base.fallback.dogleg_factor ** (characteristics[:segments_per_trip] - 1)
            end
          end
          
          committee :fuel_use_coefficients do
            quorum 'from aircraft', :needs => :aircraft, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              aircraft = characteristics[:aircraft]
              FuelUseEquation.new aircraft.m3, aircraft.m2, aircraft.m1, aircraft.endpoint_fuel
            end
            
            quorum 'from aircraft class', :needs => :aircraft_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              aircraft_class = characteristics[:aircraft_class]
              FuelUseEquation.new aircraft_class.m3, aircraft_class.m2, aircraft_class.m1, aircraft_class.endpoint_fuel
            end
            
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
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
            
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
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
            quorum 'from seats and load factor', :needs => [:seats, :load_factor], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              (characteristics[:seats] * characteristics[:load_factor]).round
            end
          end
          
          committee :seats do
            quorum 'from aircraft', :needs => :aircraft, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:aircraft].seats
            end
            
            quorum 'from seats estimate', :needs => :seats_estimate, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:seats_estimate]
            end
            
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              seats = characteristics[:cohort].weighted_average :seats, :weighted_by => :passengers
              if seats.nil? or seats.zero?
                nil
              else
                seats
              end
            end
            
            quorum 'from aircraft class', :needs => :aircraft_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:aircraft_class].seats_before_type_cast
            end
            
            quorum 'default' do
              FlightSegment.fallback.seats_before_type_cast # need before_type_cast b/c seats is an integer but the fallback value is a float
            end
          end
          
          committee :load_factor do
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:cohort].weighted_average(:load_factor, :weighted_by => :passengers)
            end
              base.fallback.andand.load_factor
            
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
            end
          end
          
          committee :freight_share do
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:cohort].weighted_average(:freight_share, :weighted_by => :passengers)
            end
            
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FlightSegment.fallback.freight_share
            end
          end
          
          committee :trips do
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              base.fallback.trips_before_type_cast # need before_type_cast b/c trips is an integer but fallback value is a float
            end
          end
          
          committee :seat_class_multiplier do
            quorum 'from seat class', :needs => :seat_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:seat_class].multiplier
            end
            
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FlightSeatClass.fallback.multiplier
            end
          end
          
          committee :country do
            quorum 'from origin airport and destination airport', :needs => [:origin_airport, :destination_airport], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              if characteristics[:origin_airport].country == characteristics[:destination_airport].country
                characteristics[:origin_airport].country
              end
            end
          end
          
          committee :cohort do
            quorum 'from segments per trip and input', :needs => :segments_per_trip, :appreciates => [:origin_airport, :destination_airport, :aircraft, :airline], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              cohort = {}
              if characteristics[:segments_per_trip] == 1
                provided_characteristics = [:origin_airport, :destination_airport, :aircraft, :airline].
                  inject(ActiveSupport::OrderedHash.new) do |memo, characteristic_name|
                    memo[characteristic_name] = characteristics[characteristic_name]
                    memo
                  end
                cohort = FlightSegment.strict_cohort provided_characteristics
              end
              if cohort.any?
                cohort
              else
                nil
              end
            end
          end
          
          committee :segments_per_trip do
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              base.fallback.segments_per_trip_before_type_cast #  need before_type_cast b/c segments_per_trip is an integer but fallback value is a float
            end
          end
          committee :date do
            quorum 'from timeframe', :complies => [:ghg_protocol, :iso, :tcr] do |characteristics, timeframe|
              timeframe.from
            end
          end
        end
      end
      
      class FuelUseEquation < Struct.new(:m3, :m2, :m1, :endpoint_fuel); end
    end
  end
end
