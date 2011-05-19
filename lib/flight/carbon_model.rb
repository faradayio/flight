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
            #### Emission from fuel use, emission factor, freight share, passengers, multipliers, and date
            quorum 'from fuel use, emission factor, freight share, passengers, multipliers, and date',
              :needs => [:fuel_use, :emission_factor, :freight_share, :passengers, :seat_class_multiplier, :aviation_multiplier, :date],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics, timeframe|
                date = characteristics[:date].is_a?(Date) ?
                  characteristics[:date] :
                  Date.parse(characteristics[:date].to_s)
                  # Checks whether the flight occurred during the `timeframe`
                if timeframe.include? date
                  # Multiplies `fuel use` (*kg*) by an `emission factor` (*kg CO<sub>2</sub>e / kg fuel*) and an `aviation multiplier` to give total flight emissions in *kg CO<sub>2</sub>e*.
                  characteristics[:fuel_use] * characteristics[:emission_factor] * characteristics[:aviation_multiplier] *
                  # Multiplies by (1 - `freight share`) to take out emissions attributed to freight cargo and mail, leaving emissions attributed to passengers and their baggage
                  (1 - characteristics[:freight_share]) /
                  # Divides by the number of `passengers` and multiplies by a `seat class multiplier` to give `emission` for the passenger
                  characteristics[:passengers] * characteristics[:seat_class_multiplier]
                else
                  # If the flight did not occur during the `timeframe`, `emission` is zero
                  0
                end
            end
          end
          
          ### Emission factor calculation
          # Returns the `emission factor` in *kg CO<sub>2</sub> / kg fuel*.
          committee :emission_factor do
            #### Emission factor from fuel
            quorum 'from fuel',
              :needs => :fuel,
              # Complies: GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Looks up the [fuel](http://data.brighterplanet.com/fuels)'s `emission factor` (*kg CO<sub>2</sub> / l*) and divides by its `density` (*kg / l*) to give *kg CO<sub>2</sub> / kg fuel*.
                characteristics[:fuel].co2_emission_factor / characteristics[:fuel].density
            end
          end
          
          ### Aviation multiplier calculation
          # Returns the `aviation multiplier`. This approximates the extra climate impact of emissions high in the atmosphere.
          committee :aviation_multiplier do
            #### Default aviation multiplier
            quorum 'default',
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                # Uses an `aviation multiplier` of **2.0** after [Kolmuss and Crimmins (2009)](http://sei-us.org/publications/id/13).
                2.0
            end
          end
          
          ### Fuel use calculation
          # Returns the flight's total `fuel use` in *kg*.
          committee :fuel_use do
            #### Fuel use from fuel per segment and segments per trip and trips
            quorum 'from fuel per segment and segments per trip and trips',
              :needs => [:fuel_per_segment, :segments_per_trip, :trips],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Multiplies the `fuel per segment` (*kg*) by the `segments per trip` and the number of `trips` to give *kg*.
                characteristics[:fuel_per_segment] * characteristics[:segments_per_trip].to_f * characteristics[:trips].to_f
            end
          end
          
          ### Fuel per segment calculation
          # Returns the `fuel per segment` in *kg*.
          committee :fuel_per_segment do
            #### Fuel per segment from adjusted distance per segment and fuel use coefficients
            quorum 'from adjusted distance per segment and fuel use coefficients',
              :needs => [:adjusted_distance_per_segment, :fuel_use_coefficients],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Uses a third-order polynomial equation to calculate the fuel used per segment:
                # 
                # (m<sub>3</sub> * d^3 ) + (m<sub>2</sub> * d^2 ) + (m<sub>1</sub> * d) + endpoint fuel
                # 
                # Where d is the `adjusted distance per segment` and m<sub>3</sub>, m<sub>2</sub>, m<sub>2</sub>, and endpoint fuel are the `fuel use coefficients`.
                characteristics[:fuel_use_coefficients].m3.to_f * characteristics[:adjusted_distance_per_segment].to_f ** 3 +
                  characteristics[:fuel_use_coefficients].m2.to_f * characteristics[:adjusted_distance_per_segment].to_f ** 2 +
                  characteristics[:fuel_use_coefficients].m1.to_f * characteristics[:adjusted_distance_per_segment].to_f +
                  characteristics[:fuel_use_coefficients].b.to_f
            end
          end
          
          ### Seat class multiplier calculation
          # Returns the `seat class multiplier`. This reflects the amount of cabin space occupied by the passenger's seat.
          committee :seat_class_multiplier do
            #### Seat class multiplier from seat class and distance
            quorum 'from seat class name and adjusted distance per segment',
              :needs => [:seat_class_name, :adjusted_distance_per_segment],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Looks up the [seat class multiplier](http://data.brighterplanet.com/flight_seat_classes) based on `distance` and `seat class`.
                if characteristics[:adjusted_distance_per_segment] < 244.06
                  FlightSeatClass.find_by_distance_class_name_and_seat_class_name("Domestic", "#{characteristics[:seat_class_name]}").multiplier
                elsif characteristics[:adjusted_distance_per_segment] < 863.93
                  FlightSeatClass.find_by_distance_class_name_and_seat_class_name("Short haul", "#{characteristics[:seat_class_name]}").multiplier
                else
                  FlightSeatClass.find_by_distance_class_name_and_seat_class_name("Long haul", "#{characteristics[:seat_class_name]}").multiplier
                end
            end
            
            #### Seat class multiplier from distance
            quorum 'from adjusted distance per segment',
              :needs => :adjusted_distance_per_segment,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Looks up the [seat class multiplier](http://data.brighterplanet.com/flight_seat_classes) based on `distance`.
                if characteristics[:adjusted_distance_per_segment] < 244.06
                  FlightSeatClass.find_by_distance_class_name_and_seat_class_name("Domestic", "unknown").multiplier
                elsif characteristics[:adjusted_distance_per_segment] < 863.93
                  FlightSeatClass.find_by_distance_class_name_and_seat_class_name("Short haul", "unknown").multiplier
                else
                  FlightSeatClass.find_by_distance_class_name_and_seat_class_name("Long haul", "unknown").multiplier
                end
            end
          end
          
          ### Seat class calculation
          # Returns the client-input [seat class](http://data.brighterplanet.com/seat_classes).
          
          ### Adjusted distance per segment calculation
          # Returns the `adjusted distance per segment` in *nautical miles*.
          committee :adjusted_distance_per_segment do
            #### Adjusted distance per segment from adjusted distance and segments per trip
            quorum 'from adjusted distance and segments per trip',
              :needs => [:adjusted_distance, :segments_per_trip],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Divides the `adjusted distance` (*nautical miles*) by `segments per trip` to give *nautical miles*.
                characteristics[:adjusted_distance] / characteristics[:segments_per_trip]
            end
          end
          
          ### Adjusted distance calculation
          # Returns the `adjusted distance` in *nautical miles*. The `adjusted distance` accounts for factors that increase the actual distance traveled by real world flights.
          committee :adjusted_distance do
            #### Adjusted distance from distance, route inefficiency factor, and dogleg factor
            quorum 'from distance, route inefficiency factor, and dogleg factor',
              :needs => [:distance, :route_inefficiency_factor, :dogleg_factor],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Multiplies `distance` (*nautical miles*) by a `route inefficiency factor` and a `dogleg factor` to give *nautical miles*.
                characteristics[:distance] * characteristics[:route_inefficiency_factor] * characteristics[:dogleg_factor]
            end
          end
          
          ### Distance calculation
          # Returns the flight's base `distance` in *nautical miles*.
          committee :distance do
            #### Distance from airports
            quorum 'from airports',
              :needs => [:origin_airport, :destination_airport],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Calculates the great circle distance between the `origin airport` and `destination airport` and converts from *km* to *nautical miles*.
                if characteristics[:origin_airport].latitude and
                    characteristics[:origin_airport].longitude and
                    characteristics[:destination_airport].latitude and
                    characteristics[:destination_airport].longitude
                  characteristics[:origin_airport].distance_to(characteristics[:destination_airport], :units => :kms).kilometres.to :nautical_miles
                end
            end
            
            #### Distance from distance estimate
            quorum 'from distance estimate',
              :needs => :distance_estimate,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Converts the `distance_estimate` in *km* to *nautical miles*.
                characteristics[:distance_estimate].kilometres.to :nautical_miles
            end
            
            #### Distance from distance class
            quorum 'from distance class',
              :needs => :distance_class,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Looks up the [distance class](http://data.brighterplanet.com/flight_distance_classes)' `distance` and converts from *km* to *nautical miles*.
                characteristics[:distance_class].distance.kilometres.to :nautical_miles
            end
            
            #### Distance from cohort
            quorum 'from cohort', :needs => :cohort do |characteristics| # cohort here will be some combo of origin OR destination, airline, and aircraft
              # Calculates the average `distance` of the `cohort` segments, weighted by their passengers, and converts from *km* to *nautical miles*.
              distance = characteristics[:cohort].weighted_average(:distance, :weighted_by => :passengers).kilometres.to(:nautical_miles)
              distance > 0 ? distance : nil
            end
            
            #### Default distance
            quorum 'default' do
              # Calculates the average `distance` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers, and converts from *km* to *nautical miles*.
              FlightSegment.fallback.distance.kilometres.to :nautical_miles
            end
          end
          
          ### Route inefficiency factor calculation
          # Returns the `route inefficiency factor`. This is a measure of how much farther real world flights travel than the great circle distance between their origin and destination. It accounts for factors like flight path routing around controlled airspace and circling while waiting for clearance to land.
          committee :route_inefficiency_factor do
            #### Route inefficiency factor from country
            quorum 'from country',
              :needs => :country,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Looks up the `route inefficiency factor` for the [country](http://data.brighterplanet.com/countries) in which the flight occurs.
                characteristics[:country].andand.flight_route_inefficiency_factor
            end
            
            #### Default route inefficiency factor
            quorum 'default',
            # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                # Uses a `route inefficiency factor` of **10%** based on [Kettunen et al. (2005)](http://www.atmseminar.org/seminarContent/seminar6/papers/p_055_MPM.pdf)
                Country.fallback.flight_route_inefficiency_factor
            end
          end
          
          ### Dogleg factor calculation
          # Returns the `dogleg factor`. This is a measure of how far out of the way the average layover is compared to a direct flight.
          committee :dogleg_factor do
            #### Dogleg factor from segments per trip
            quorum 'from segments per trip',
              :needs => :segments_per_trip,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Assumes that each layover increases the total flight distance by **25%**.
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
            quorum 'from aircraft',
              :needs => :aircraft,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Looks up the [aircraft](http://data.brighterplanet.com/aircraft)'s `fuel use coefficients`.
                if equation = characteristics[:aircraft].fuel_use_equation
                  fuel_use = FuelUseEquation.new equation.m3, equation.m2, equation.m1, equation.b
                end
            end
            
            #### Fuel use coefficients from cohort
            quorum 'from cohort',
              :needs => :cohort,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                flight_segments = characteristics[:cohort]
                
                total_passengers = flight_segments.map(&:passengers).sum
                fue = Flight::FuelUseEquation.new(0, 0, 0, 0)
                flight_segments.each do |fs|
                  fuel_use_codes = []
                  class_codes = []
                  fs.aircraft.each do |a|
                    if a.fuel_use_code.present?
                      fuel_use_codes.push(a.fuel_use_code)
                    else
                      class_codes.push(a.class_code)
                    end
                  end
                  
                  # combine these into an array because otherwise you have to check whether either ActiveRecord::Relation is empty
                  equations = AircraftFuelUseEquation.where(:code => fuel_use_codes) + AircraftClass.where(:code => class_codes)
                  %w{ m3 m2 m1 b }.each do |coefficient|
                    fue.send("#{coefficient}=",
                      fue.send("#{coefficient}") +
                      ((equations.map(&:"#{coefficient}").sum / equations.size) * fs.passengers)
                    )
                  end
                end
                
                %w{ m3 m2 m1 b }.each do |coefficient|
                  fue.send("#{coefficient}=", (fue.send("#{coefficient}") / total_passengers))
                end
                fue
            end
            
            #### Default fuel use coefficients
            quorum 'default',
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                # Calculates the average `fuel use coefficients` of the aircraft used by [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by the segment passengers.
                FuelUseEquation.new AircraftFuelUseEquation.fallback.m3, AircraftFuelUseEquation.fallback.m2, AircraftFuelUseEquation.fallback.m1, AircraftFuelUseEquation.fallback.b
            end
          end
          
          ### Fuel calculation
          # Returns the `fuel`.
          committee :fuel do
            #### Fuel from client input
            # **Complies:** All
            #
            # Uses the client-input [fuel](http://data.brighterplanet.com/fuels).
            
            #### Default fuel
            quorum 'default',
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                # Assumes the flight uses **Jet Fuel**.
                Fuel.find_by_name 'Jet Fuel'
            end
          end
          
          ### Passengers calculation
          # Returns the number of `passengers`.
          committee :passengers do
            #### Passengers from seats and load factor
            quorum 'from seats and load factor',
              :needs => [:seats, :load_factor],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Multiplies the number of `seats` by the `load factor`.
                (characteristics[:seats] * characteristics[:load_factor]).round
            end
          end
          
          ### Seats calculation
          # Returns the number of `seats`.
          committee :seats do
            #### Seats from seats estimate
            quorum 'from seats estimate',
              :needs => :seats_estimate,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Uses the client-input estimate of the number of `seats`.
                characteristics[:seats_estimate]
            end
            
            #### Seats from aircraft
            quorum 'from aircraft',
              :needs => :aircraft,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Looks up the [aircraft](http://data.brighterplanet.com/aircraft)'s average number of `seats`.
                characteristics[:aircraft].seats
            end
            
            #### Seats from cohort
            quorum 'from cohort',
              :needs => :cohort,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Calculates the average number of `seats` of the `cohort` segments, weighted by their passengers.
                seats = characteristics[:cohort].weighted_average :seats, :weighted_by => :passengers
                if seats.nil? or seats.zero?
                  nil
                else
                  seats
                end
            end
            
            #### Default seats
            quorum 'default',
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                # Calculates the average number of `seats` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
                FlightSegment.fallback.seats
            end
          end
          
          ### Seats estimate calculation
          # Returns the client-input `seats estimate`.
          
          ### Load factor calculation
          # Returns the `load factor`. This is the portion of available seats that are occupied.
          committee :load_factor do
            #### Load factor from client input
            # **Complies:** All
            #
            # Uses the client-input `load factor`.
            
            #### Load factor from cohort
            quorum 'from cohort',
              :needs => :cohort,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Calculates the average `load factor` of the `cohort` segments, weighted by their passengers.
                characteristics[:cohort].weighted_average(:load_factor, :weighted_by => :passengers)
            end
            
            #### Default load factor
            quorum 'default',
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                # Calculates the average `load factor` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
                FlightSegment.fallback.load_factor
            end
          end
          
          ### Freight share calculation
          # Returns the `freight share`. This is the percent of the total aircraft weight that is freight cargo and mail (as opposed to passengers and their baggage).
          committee :freight_share do
            #### Freight share from cohort
            quorum 'from cohort',
              :needs => :cohort,
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Calculates the average `freight share` of the `cohort` segments, weighted by their passengers.
                characteristics[:cohort].weighted_average(:freight_share, :weighted_by => :passengers)
            end
            
            #### Default freight share
            quorum 'default',
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                # Calculates the average `freight share` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
                FlightSegment.fallback.freight_share
            end
          end
          
          ### Trips calculation
          # Returns the number of `trips`. A one-way flight has one trip; a round-trip flight has two trips.
          committee :trips do
            #### Trips from client input
            # **Complies:** All
            #
            # Uses the client-input number of `trips`.
            
            #### Default trips
            quorum 'default',
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                # Uses an average number of `trips` of **1.7** calculated from the [BTS Origin and Destination Survey](https://spreadsheets.google.com/pub?key=0Anc8M0qoN5VidC1ESzRRb21zaVRodkN6TF95M3JQeUE&hl=en&output=html).
                1.7
            end
          end
          
          ### Country calculation
          # Returns the [country](http://data.brighterplanet.com/countries) in which a flight occurs.
          committee :country do
            #### Country from client input
            # **Complies:** All
            #
            # Uses the client-input [country](http://data.brighterplanet.com/countries).
            
            #### Country from origin airport and destination airport
            quorum 'from origin airport and destination airport',
              :needs => [:origin_airport, :destination_airport],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                # Checks whether the flight's `origin airport` and `destination airport` are within the same country. If so, that country is the `country`.
                if characteristics[:origin_airport].country == characteristics[:destination_airport].country
                  characteristics[:origin_airport].country
                end
            end
          end
          
          ### Cohort calculation
          # Returns the `cohort`. This is a set of flight segment records in the [T-100 database](http://data.brighterplanet.com/flight_segments) that match certain client-input values.
          committee :cohort do
            #### Cohort from segments per trip and input
            quorum 'from segments per trip and input',
              :needs => :segments_per_trip, :appreciates => [:origin_airport, :destination_airport, :aircraft, :airline, :date],
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                cohort = {}
                
                # Only assemble a cohort if the flight is direct
                if characteristics[:segments_per_trip] == 1
                  # If we have both an origin and destination airport...
                  if characteristics[:origin_airport] and characteristics[:destination_airport]
                    # If either airport is in the US...
                    if characteristics[:origin_airport].country_iso_3166_code == "US" or characteristics[:destination_airport].country_iso_3166_code == "US"
                      # Use airport iata code to assemble a cohort of BTS flight segments
                      provided_characteristics = [
                        [:origin_airport_iata_code, characteristics[:origin_airport].iata_code],
                        [:destination_airport_iata_code, characteristics[:destination_airport].iata_code]
                      ]
                      end
                    else
                      # Otherwise, use airport city to assemble a cohort of ICAO flight segments
                      provided_characteristics = [
                        [:origin_airport_city, characteristics[:origin_airport].city],
                        [:destination_airport_city, characteristics[:destination_airport].city]
                      ]
                    end
                    
                    # Also use aircraft description and airline name
                    provided_characteristics.push [:aircraft_description, characteristics[:aircraft].description],
                      [:airline_name, characteristics[:airline].name]
                    
                    # To assemble a cohort, we select all the records in our flight segments database that match
                    # the input `origin_airport`, `destination_airport`, `aircraft`, and `airline`. If no records
                    # match all the inputs, we drop the last input (initially `airline`) and try again. We continue
                    # until some records match or no input values remain.
                    cohort = FlightSegment.strict_cohort(*provided_characteristics)
                    
                    # Ignore the cohort if none of the flight segments have any passengers
                    if cohort.any? && cohort.any? { |fs| fs.passengers.nonzero? }
                      cohort
                    else
                      nil
                    end
                  
                  # If we don't have both origin and destination
                  else
                    # First use airport iata code to assemble a cohort of BTS flight segments
                    provided_characteristics = [
                      [:origin_airport_iata_code, characteristics[:origin_airport].iata_code],
                      [:destination_airport_iata_code, characteristics[:destination_airport].iata_code],
                      [:aircraft_description, characteristics[:aircraft].description],
                      [:airline_name, characteristics[:airline].name]
                    ]
                    bts_cohort = FlightSegment.strict_cohort(*provided_characteristics)
                    
                    # Then use airport city to assemble a cohort of ICAO flight segments
                    provided_characteristics = [
                      [:origin_airport_city, characteristics[:origin_airport].city],
                      [:destination_airport_city, characteristics[:destination_airport].city],
                      [:aircraft_description, characteristics[:aircraft].description],
                      [:airline_name, characteristics[:airline].name]
                    ]
                    icao_cohort = FlightSegment.strict_cohort(*provided_characteristics)
                    
                    # Combine the two cohorts...
                    cohort = bts_cohort + icao_cohort
                    
                    # And ensure at least one of the flight segments has passengers
                    if cohort.any? && cohort.any? { |fs| fs.passengers.nonzero? }
                      cohort
                    else
                      nil
                    end
                end
            end
          end
          
          ### Origin airport calculation
          # Returns the client-input [origin airport](http://data.brighterplanet.com/airports).
          
          ### Destination airport calculation
          # Returns the client-input [destination airport](http://data.brighterplanet.com/airports).
          
          ### Aircraft calculation
          # Returns the client-input of [aircraft](http://data.brighterplanet.com/aircraft).
          
          ### Airline calculation
          # Returns the client-input [airline](http://data.brighterplanet.com/airlines) operating the flight.
          
          ### Segments per trip calculation
          # Returns the `segments per trip`. Direct flights have a single segment per trip. Indirect flights with one or more layovers have two or more segments per trip.
          committee :segments_per_trip do
            #### Segments per trip from client input
            # **Complies:** All
            #
            # Uses the client-input `segments per trip`.
            
            #### Default segments per trip
            quorum 'default',
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                # Uses an average `segments per trip` of **1.68**, calculated from the [BTS Origin and Destination Survey](https://spreadsheets.google.com/pub?key=0Anc8M0qoN5VidC1ESzRRb21zaVRodkN6TF95M3JQeUE&hl=en&output=html).
                1.68
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
            quorum 'from timeframe',
              # **Complies:** GHG Protocol Scope 3, ISO-14064-1, Climate Registry Protocol
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics, timeframe|
                # Assumes the flight occurred on the first day of the `timeframe`.
                timeframe.from
            end
          end
          
          ### Timeframe calculation
          # Returns the `timeframe`. This is the period during which to calculate emissions.
            
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
