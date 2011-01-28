# Copyright © 2010 Brighter Planet.
# See LICENSE for details.
# Contact Brighter Planet for dual-license arrangements.

require 'leap'
require 'timeframe'
require 'date'
require 'weighted_average'
require 'builder'
require 'flight/carbon_model/fuel_use_equation'

## Flight carbon model
# This model is used by [Brighter Planet](http://brighterplanet.com)'s carbon emission [web service](http://carbon.brighterplanet.com) to estimate the **greenhouse gas emissions of passenger air travel**.
#
##### Timeframe and date
# The model estimates the emissions that occur during a particular `timeframe`. To do this it needs to know the `date` on which the flight occurred. For example, if the `timeframe` is January 2010, a flight that occurred on January 5, 2010 will have emissions but a flight that occurred on February 1, 2010 will not.
#
##### Calculations
# The final estimate is the result of the **calculations** detailed below. These calculations are performed in reverse order, starting with the last calculation listed and finishing with the `emission` calculation. Each calculation is named according to the value it returns.
#
##### Methods
# To accomodate varying client input, each calculation may have one or more **methods**. These are listed under each calculation in order from most to least preferred. Each method is named according to the values it requires. If any of these values is not available the method will be ignored. If all the methods for a calculation are ignored, the calculation will not return a value. "Default" methods do not require any values, and so a calculation with a default method will always return a value.
#
##### Standard compliance
# Each method lists any established calculation standards with which it **complies**. When compliance with a standard is requested, all methods that do not comply with that standard are ignored. This means that any values a particular method requires will have been calculated using a compliant method, because those are the only methods available. If any value did not have a compliant method in its calculation then it would be undefined, and the current method would have been ignored.
#
##### Collaboration
# Contributions to this carbon model are actively encouraged and warmly welcomed. This library includes a comprehensive test suite to ensure that your changes do not cause regressions. All changes should include test coverage for new functionality. Please see [sniff](http://github.com/brighterplanet/sniff#readme), our emitter testing framework, for more information.
module BrighterPlanet
  module Flight
    module CarbonModel
      def self.included(base)
        base.decide :emission, :with => :characteristics do
          ### Emission calculation
          # Returns the `emission` estimate in *kg CO<sub>2</sub>e*.
          # This is the passenger's share of the total flight emissions that occurred during the `timeframe`.
          committee :emission do
            #### Emission from fuel, emission factor, freight share, passengers, multipliers, and date
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # - Checks whether the flight occurred during the `timeframe`
            # - Multiplies `fuel use` (*kg fuel*) by an `emission factor` (*kg CO<sub>2</sub>e / kg fuel*) and an `aviation multiplier` to give total flight emissions in *kg CO<sub>2</sub>e*
            # - Multiplies by (1 - `freight share`) to take out emissions attributed to freight cargo and mail, leaving emissions attributed to passengers and their baggage
            # - Divides by the number of `passengers` and multiplies by a `seat class multiplier` to give `emission` for the passenger
            # - If the flight did not occur during the `timeframe`, `emission` is zero
            quorum 'from fuel, emission factor, freight share, passengers, multipliers, and date',
              :needs => [:fuel, :emission_factor, :freight_share, :passengers, :seat_class_multiplier, :aviation_multiplier, :date], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics, timeframe|
              date = characteristics[:date].is_a?(Date) ?
                characteristics[:date] :
                Date.parse(characteristics[:date].to_s)
              if timeframe.include? date
                characteristics[:fuel] * characteristics[:emission_factor] * characteristics[:aviation_multiplier] * (1 - characteristics[:freight_share]) / characteristics[:passengers] * characteristics[:seat_class_multiplier]
              else
                0
              end
            end
          end
          
          ### Emission factor calculation
          # Returns the `emission factor` in *kg CO<sub>2</sub>e / kg fuel*.
          committee :emission_factor do
            #### Emission factor from fuel type
            # Complies: GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [fuel type](http://data.brighterplanet.com/fuel_types) and divides its `emission factor` (*kg CO<sub>2</sub> / litre fuel*) by its `density` (*kg fuel / litre fuel*) to give *kg CO<sub>2</sub>e / kg fuel*.
            quorum 'from fuel type', :needs => :fuel_type, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:fuel_type].emission_factor.to_f / characteristics[:fuel_type].density.to_f
            end
          end
          
          ### Aviation multiplier calculation
          # Returns the `aviation multiplier`. This approximates the extra climate impact of emissions high in the atmosphere.
          committee :aviation_multiplier do
            #### Default aviation multiplier
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Uses an `aviation multiplier` of **2.0** after [Kolmuss and Crimmins (2009)](http://sei-us.org/publications/id/13).
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              2.0
            end
          end
          
          ### Fuel calculation
          # Returns the flight's total `fuel` use in *kg fuel*.
          committee :fuel do
            #### Fuel from fuel per segment and segments per trip and trips
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Multiplies the `fuel per segment` (*kg fuel*) by the `segments per trip` and the number of `trips` to give *kg fuel*.
            quorum 'from fuel per segment and segments per trip and trips', :needs => [:fuel_per_segment, :segments_per_trip, :trips], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:fuel_per_segment] * characteristics[:segments_per_trip].to_f * characteristics[:trips].to_f
            end
          end
          
          ### Fuel per segment calculation
          # Returns the `fuel per segment` in *kg fuel*.
          committee :fuel_per_segment do
            #### Fuel per segment from adjusted distance per segment and fuel use coefficients
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Uses a third-order polynomial equation to calculate the fuel used per segment:
            #
            # (m<sub>3</sub> * d^3 ) + (m<sub>2</sub> * d^2 ) + (m<sub>1</sub> * d) + endpoint fuel
            #
            # Where d is the `adjusted distance per segment` and m<sub>3</sub>, m<sub>2</sub>, m<sub>2</sub>, and endpoint fuel are the `fuel use coefficients`.
            quorum 'from adjusted distance per segment and fuel use coefficients', :needs => [:adjusted_distance_per_segment, :fuel_use_coefficients], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:fuel_use_coefficients].m3.to_f * characteristics[:adjusted_distance_per_segment].to_f ** 3 +
                characteristics[:fuel_use_coefficients].m2.to_f * characteristics[:adjusted_distance_per_segment].to_f ** 2 +
                characteristics[:fuel_use_coefficients].m1.to_f * characteristics[:adjusted_distance_per_segment].to_f +
                characteristics[:fuel_use_coefficients].endpoint_fuel.to_f
            end
          end
          
          ### Adjusted distance per segment calculation
          # Returns the `adjusted distance per segment` in *nautical miles*.
          committee :adjusted_distance_per_segment do
            #### Adjusted distance per segment from adjusted distance and segments per trip
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Divides the `adjusted distance` (*nautical miles*) by `segments per trip` to give *nautical miles*.
            quorum 'from adjusted distance and segments per trip', :needs => [:adjusted_distance, :segments_per_trip], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:adjusted_distance] / characteristics[:segments_per_trip]
            end
          end
          
          ### Adjusted distance calculation
          # Returns the `adjusted distance` in *nautical miles*.
          # The `adjusted distance` accounts for factors that increase the actual distance traveled by real world flights.
          committee :adjusted_distance do
            #### Adjusted distance from distance, route inefficiency factor, and dogleg factor
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Multiplies `distance` (*nautical miles*) by a `route inefficiency factor` and a `dogleg factor` to give *nautical miles*.
            quorum 'from distance, route inefficiency factor, and dogleg factor', :needs => [:distance, :route_inefficiency_factor, :dogleg_factor], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:distance] * characteristics[:route_inefficiency_factor] * characteristics[:dogleg_factor]
            end
          end
          
          ### Distance calculation
          # Returns the flight's base `distance` in *nautical miles*.
          committee :distance do
            #### Distance from airports
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the great circle distance between the `origin airport` and `destination airport` and converts from *km* to *nautical miles*.
            quorum 'from airports', :needs => [:origin_airport, :destination_airport], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              if  characteristics[:origin_airport].latitude and
                  characteristics[:origin_airport].longitude and
                  characteristics[:destination_airport].latitude and
                  characteristics[:destination_airport].longitude
                characteristics[:origin_airport].distance_to(characteristics[:destination_airport], :units => :kms).kilometres.to :nautical_miles
              end
            end
            
            #### Distance from distance estimate
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Converts the `distance_estimate` in *km* to *nautical miles*.
            quorum 'from distance estimate', :needs => :distance_estimate, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:distance_estimate].kilometres.to :nautical_miles
            end
            
            #### Distance from distance class
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [distance class](http://data.brighterplanet.com/flight_distance_classes)' `distance` and converts from *km* to *nautical miles*.
            quorum 'from distance class', :needs => :distance_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:distance_class].distance.kilometres.to :nautical_miles
            end
            
            #### Distance from cohort
            # **Complies:**
            #
            # Calculates the average `distance` of the `cohort` segments, weighted by their passengers, and converts from *km* to *nautical miles*.
            quorum 'from cohort', :needs => :cohort do |characteristics| # cohort here will be some combo of origin, airline, and aircraft
              distance = characteristics[:cohort].weighted_average(:distance, :weighted_by => :passengers).kilometres.to(:nautical_miles)
              distance > 0 ? distance : nil
            end
            
            #### Default distance
            # **Complies:**
            #
            # Calculates the average `distance` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers, and converts from *km* to *nautical miles*.
            quorum 'default' do
              FlightSegment.fallback.distance.kilometres.to :nautical_miles
            end
          end
          
          ### Route inefficiency factor calculation
          # This calculation returns the `route inefficiency factor`.
          # This is a measure of how much farther real world flights travel than the great circle distance between their origin and destination.
          # It accounts for factors like flight path routing around controlled airspace and circling while waiting for clearance to land.
          committee :route_inefficiency_factor do
            #### Route inefficiency factor from country
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the `route inefficiency factor` for the [country](http://data.brighterplanet.com/countries) in which the flight occurs.
            quorum 'from country', :needs => :country, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:country].andand.flight_route_inefficiency_factor
            end
            
            #### Default route inefficiency factor
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Uses a `route inefficiency factor` of **10%** based on [Kettunen et al. (2005)](http://www.atmseminar.org/seminarContent/seminar6/papers/p_055_MPM.pdf)
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              Country.fallback.flight_route_inefficiency_factor
            end
          end
          
          ### Dogleg factor calculation
          # Returns the `dogleg factor`.
          # This is a measure of how far out of the way the average layover is compared to a direct flight.
          committee :dogleg_factor do
            #### Dogleg factor from segments per trip
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Assumes that each layover increases the total flight distance by **25%**.
            quorum 'from segments per trip', :needs => :segments_per_trip, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              1.25 ** (characteristics[:segments_per_trip] - 1)
            end
          end
          
          ### Distance estimate calculation
          # Returns the client-input `distance estimate` in *km*.
          
          ### Distance class calculation
          # Returns the client-input [distance class](http://data.brighterplanet.com/distance_classes).
          
          ### Fuel use coefficients calculation
          # Returns the `fuel use coefficients`. These are the coefficients of the third-order polynomial equation that describes aircraft fuel use.
          committee :fuel_use_coefficients do
            #### Fuel use coefficients from aircraft
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [aircraft](http://data.brighterplanet.com/aircraft)'s `fuel use coefficients`.
            quorum 'from aircraft', :needs => :aircraft, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              aircraft = characteristics[:aircraft]
              fuel_use = FuelUseEquation.new aircraft.m3, aircraft.m2, aircraft.m1, aircraft.endpoint_fuel
              if fuel_use.empty?
                nil
              else
                fuel_use
              end
            end
            
            #### Fuel use coefficients from aircraft class
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [aircraft class](http://data.brighterplanet.com/aircraft_classes)' `fuel use coefficients`.
            quorum 'from aircraft class', :needs => :aircraft_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              aircraft_class = characteristics[:aircraft_class]
              FuelUseEquation.new aircraft_class.m3, aircraft_class.m2, aircraft_class.m1, aircraft_class.endpoint_fuel
            end
            
            #### Fuel use coefficients from cohort
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average `fuel use coefficients` of the aircraft used by the `cohort` segments, weighted by the segment passengers.
            # If an aircraft does not have `fuel use coefficients`, it takes the `fuel use coefficients` for the aircraft's [aircraft class](http://data.brighterplanet.com/aircraft_classes).
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              flight_segments = characteristics[:cohort]
              
              passengers = flight_segments.inject(0) do |passengers, flight_segment|
                passengers + flight_segment.passengers
              end
              
              bts_codes = flight_segments.map(&:aircraft_bts_code).uniq
              relevant_aircraft = Aircraft.find_all_by_bts_code(bts_codes).inject({}) do |hsh, aircraft|
                hsh[aircraft.bts_code] = aircraft
                hsh
              end

              sum_coefficients = lambda do |name|
                flight_segments.inject(0) do |coefficient, flight_segment|
                  bts_code = flight_segment.aircraft_bts_code.to_s
                  aircraft = relevant_aircraft[bts_code]
                  aircraft_coefficient = aircraft.send(name)
                  if aircraft_coefficient.nil?
                    aircraft_coefficient = aircraft.aircraft_class.send(name)
                  end
                  coefficient + (aircraft_coefficient * flight_segment.passengers)
                end
              end

              m3 = sum_coefficients.call(:m3) / passengers
              m2 = sum_coefficients.call(:m2) / passengers
              m1 = sum_coefficients.call(:m1) / passengers
              endpoint_fuel = sum_coefficients.call(:endpoint_fuel) / passengers
              
              FuelUseEquation.new m3, m2, m1, endpoint_fuel
            end
            
            #### Default fuel use coefficients
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average `fuel use coefficients` of the aircraft used by [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by the segment passengers.
            # If an aircraft does not have `fuel use coefficients`, it takes the `fuel use coefficients` for the aircraft's [aircraft class](http://data.brighterplanet.com/aircraft_classes).
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FuelUseEquation.new Aircraft.fallback.m3, Aircraft.fallback.m2, Aircraft.fallback.m1, Aircraft.fallback.endpoint_fuel
            end
          end
          
          ### Fuel type calculation
          # Returns the `fuel type`.
          committee :fuel_type do
            #### Fuel type from client input
            # **Complies:** All
            #
            # Uses the client-input [fuel type](http://data.brighterplanet.com/fuel_types).
            
            #### Default fuel type
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Assumes the flight uses **Jet Fuel**.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FuelType.find_by_name 'Jet Fuel'
            end
          end
          
          ### Passengers calculation
          # Returns the number of `passengers`.
          committee :passengers do
            #### Passengers from seats and load factor
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Multiplies the number of `seats` by the `load factor`.
            quorum 'from seats and load factor', :needs => [:seats, :load_factor], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              (characteristics[:seats] * characteristics[:load_factor]).round
            end
          end
          
          ### Seats calculation
          # Returns the number of `seats`.
          committee :seats do
            #### Seats from seats estimate
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Uses the client-input estimate of the number of `seats`.
            quorum 'from seats estimate', :needs => :seats_estimate, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:seats_estimate]
            end
            
            #### Seats from aircraft
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [aircraft](http://data.brighterplanet.com/aircraft)'s average number of `seats`.
            quorum 'from aircraft', :needs => :aircraft, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:aircraft].seats
            end
            
            #### Seats from aircraft class
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [aircraft class](http://data.brighterplanet.com/aircraft_classes)' average number of `seats`.
            quorum 'from aircraft class', :needs => :aircraft_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:aircraft_class].seats
            end
            
            #### Seats from cohort
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average number of `seats` of the `cohort` segments, weighted by their passengers.
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              seats = characteristics[:cohort].weighted_average :seats, :weighted_by => :passengers
              if seats.nil? or seats.zero?
                nil
              else
                seats
              end
            end
            
            #### Default seats
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average number of `seats` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FlightSegment.fallback.seats
            end
          end
          
          ### Seats estimate calculation
          # Returns the client-input `seats estimate`.
          
          ### Load factor calculation
          # Returns the `load factor`.
          # This is the portion of available seats that are occupied.
          committee :load_factor do
            #### Load factor from client input
            # **Complies:** All
            #
            # Uses the client-input `load factor`.
            
            #### Load factor from cohort
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average `load factor` of the `cohort` segments, weighted by their passengers.
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:cohort].weighted_average(:load_factor, :weighted_by => :passengers)
            end
            
            #### Default load factor
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average `load factor` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FlightSegment.fallback.load_factor
            end
          end
          
          ### Freight share calculation
          # Returns the `freight share`.
          # This is the percent of the total aircraft weight that is freight cargo and mail (as opposed to passengers and their baggage).
          committee :freight_share do
            #### Freight share from cohort
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average `freight share` of the `cohort` segments, weighted by their passengers.
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:cohort].weighted_average(:freight_share, :weighted_by => :passengers)
            end
            
            #### Default freight share
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average `freight share` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FlightSegment.fallback.freight_share
            end
          end
          
          ### Trips calculation
          # Returns the number of `trips`.
          # A one-way flight has one trip; a round-trip flight has two trips.
          committee :trips do
            #### Trips from client input
            # **Complies:** All
            #
            # Uses the client-input number of `trips`.
            
            #### Default trips
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Uses an average number of `trips` of **1.941**, taken from the [U.S. National Household Travel Survey](http://www.bts.gov/publications/america_on_the_go/long_distance_transportation_patterns/html/table_07.html).
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              1.941
            end
          end
          
          ### Seat class multiplier calculation
          # Returns the `seat class multiplier`. This reflects the amount of cabin space occupied by the passenger's seat.
          committee :seat_class_multiplier do
            #### Seat class multiplier from seat class
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [seat class](http://data.brighterplanet.com/flight_seat_classes)' `seat class multiplier`.
            quorum 'from seat class', :needs => :seat_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:seat_class].multiplier
            end
            
            #### Default seat class multiplier
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Uses a `seat class multiplier` of **1**.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FlightSeatClass.fallback.multiplier
            end
          end
          
          ### Seat class calculation
          # Returns the client-input [seat class](http://data.brighterplanet.com/seat_classes).
          
          ### Country calculation
          # Returns the [country](http://data.brighterplanet.com/countries) in which a flight occurs.
          committee :country do
            #### Country from client input
            # **Complies:** All
            #
            # Uses the client-input [country](http://data.brighterplanet.com/countries).
            
            #### Country from origin airport and destination airport
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Checks whether the flight's `origin airport` and `destination airport` are within the same country.
            # If so, that country is the `country`.
            quorum 'from origin airport and destination airport', :needs => [:origin_airport, :destination_airport], :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              if characteristics[:origin_airport].country == characteristics[:destination_airport].country
                characteristics[:origin_airport].country
              end
            end
          end
          
          ### Aircraft Class calculation
          # This calculation returns the [aircraft class](http://data.brighterplanet.com/aircraft_classes).
          committee :aircraft_class do
            #### Aircraft class from client input
            # **Complies:** All
            #
            # Uses the client-input [aircraft_class](http://data.brighterplanet.com/aircraft_classes).
            
            #### Aircraft class from aircraft
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [aircraft](http://data.brighterplanet.com/aircraft)'s [aircraft_class](http://data.brighterplanet.com/aircraft_classes).
            quorum 'from aircraft', :needs => :aircraft, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:aircraft].aircraft_class
            end
          end
          
          ### Cohort calculation
          # Returns the `cohort`.
          # This is a set of flight segment records in the [T-100 database](http://data.brighterplanet.com/flight_segments) that match certain client-input values.
          committee :cohort do
            #### Cohort from segments per trip and input
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # - Checks whether the flight is direct
            # - Takes the input values for `origin airport`, `destination airport`, `aircraft`, and `airline`
            # - Selects all the records in the T-100 database that match the available input values
            # - Drops the last input value (initially `airline`, then `aircraft`, etc.) if no records match all of the available input values
            # - Repeats steps 3 and 4 until some records match or no input values remain
            # - If no records match any of the input values, or if the flight is indirect, then `cohort` is undefined.
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
              if cohort.any? && !cohort.all? { |fs| fs.passengers.zero? }
                cohort
              else
                nil
              end
            end
          end
          
          ### Origin airport calculation
          # Returns the client-input [origin airport](http://data.brighterplanet.com/airports).
          
          ### Destination airport calculation
          # Returns the client-input [destination airport](http://data.brighterplanet.com/airports).
          
          ### Aircraft calculation
          # Returns the client-input type of [aircraft](http://data.brighterplanet.com/aircraft).
          
          ### Airline calculation
          # Returns the client-input [airline](http://data.brighterplanet.com/airlines) operating the flight.
          
          ### Segments per trip calculation
          # Returns the `segments per trip`.
          # Direct flights have a single segment per trip. Indirect flights with one or more layovers have two or more segments per trip.
          committee :segments_per_trip do
            #### Segments per trip from client input
            # **Complies:** All
            #
            # Uses the client-input `segments per trip`.
            
            #### Default segments per trip
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Uses an average `segments per trip` of **1.67**, calculated from the [U.S. National Household Travel Survey](http://nhts.ornl.gov/).
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              1.67
            end
          end
          
          ### Date calculation
          # Returns the `date` on which the flight occurred.
          committee :date do
            #### Date from client input
            # **Complies:** All
            #
            # Uses the client-input `date`.
            
            #### Date from timeframe
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Assumes the flight occurred on the first day of the `timeframe`.
            quorum 'from timeframe', :complies => [:ghg_protocol, :iso, :tcr] do |characteristics, timeframe|
              timeframe.from
            end
          end
          
          ### Timeframe calculation
          # Returns the `timeframe`.
          # This is the period during which to calculate emissions.
            
            #### Timeframe from client input
            # **Complies:** All
            #
            # Uses the client-input `timeframe`.
            
            #### Default timeframe
            # **Complies:** All
            #
            # Uses the current calendar year.
        end
      end
    end
  end
end
