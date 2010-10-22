require 'leap'
require 'timeframe'
require 'date'
require 'weighted_average'

## Flight carbon model
# This model is used by [Brighter Planet](http://brighterplanet.com)'s carbon emission [web service](http://carbon.brighterplanet.com) to estimate the **greenhouse gas emissions of passenger air travel**.
#
# The model estimates the emissions that occur during a particular `timeframe`. For example, if the `timeframe` is January 2010, a flight that occured on January 5, 2010 will have emissions but a flight that occured on February 1, 2010 will not. If no `timeframe` is specified, the default is the current year.
#
# The final estimate is the result of the **calculations** detailed below.
# These calculations are performed in reverse order, starting with the last calculation listed and finishing with the `emission` calculation. Each calculation is named according to the value it returns.
#
# To accomodate varying client input, each calculation may have one or more **methods**. These are listed under each calculation in order from most to least preferred. Each method is named according to the values it requires. "Default" methods do not require any values.
#
# Each method lists any established calculation standards with which it potentially **complies**. The value produced by a method only complies with a standard if all the values the method required were calculated using methods that comply with the standard (client-input values comply with all standards). Since compliance is evaluated in this way for every method, the result is that a final `emission` estimate only complies with a standard if every calculation that produced it used a method that complies with the standard.
module BrighterPlanet
  module Flight
    module CarbonModel
      def self.included(base)
        base.extend FastTimestamp
        base.decide :emission, :with => :characteristics do
          ### Emission calculation
          # Returns the `emission` estimate in *kg CO<sub>2</sub>e*.
          # This is the passenger's share of the total flight emissions that occured during the `timeframe`.
          committee :emission do
            #### From fuel, emission factor, freight share, passengers, multipliers, and date
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # - Checks whether the flight occured during the `timeframe`
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
            
            #### Default
            # **Complies:**
            #
            # Displays an error message if the previous method fails.
            quorum 'default' do
              raise "The emission committee's default quorum should never be called"
            end
          end
          
          ### Emission factor calculation
          # Returns the `emission factor` in *kg CO<sub>2</sub>e / kg fuel*.
          committee :emission_factor do
            #### From fuel type
            # Complies: GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [fuel type](http://data.brighterplanet.com/fuel_types) and divides its `emission factor` (*kg CO<sub>2</sub> / litre fuel*) by its `density` (*kg fuel / litre fuel*) to give *kg CO<sub>2</sub>e / kg fuel*.
            quorum 'from fuel type', :needs => :fuel_type, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:fuel_type].emission_factor / characteristics[:fuel_type].density
            end
          end
          
          ### Aviation multiplier calculation
          # Returns the `aviation multiplier`. This approximates the extra climate impact of emissions high in the atmosphere.
          committee :aviation_multiplier do
            #### Default
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
            #### From fuel per segment and segments per trip and trips
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
            #### From adjusted distance per segment and fuel use coefficients
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
            #### From adjusted distance and segments per trip
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
            #### From distance, route inefficiency factor, and dogleg factor
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
            #### From airports
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
            
            #### From distance estimate
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Converts the `distance_estimate` in *km* to *nautical miles*.
            quorum 'from distance estimate', :needs => :distance_estimate, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:distance_estimate].kilometres.to :nautical_miles
            end
            
            #### From distance class
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [distance class](http://data.brighterplanet.com/flight_distance_classes)' `distance` and converts from *km* to *nautical miles*.
            quorum 'from distance class', :needs => :distance_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:distance_class].distance.kilometres.to :nautical_miles
            end
            
            #### From cohort
            # **Complies:**
            #
            # Calculates the average `distance` of the `cohort` segments, weighted by their passengers, and converts from *km* to *nautical miles*.
            quorum 'from cohort', :needs => :cohort do |characteristics| # cohort here will be some combo of origin, airline, and aircraft
              distance = characteristics[:cohort].weighted_average(:distance, :weighted_by => :passengers).kilometres.to(:nautical_miles)
              distance > 0 ? distance : nil
            end
            
            #### Default
            # **Complies:**
            #
            # Looks up the default `distance`.
            quorum 'default' do #Calculates the average `distance` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers, and converts from *km* to *nautical miles*.
              FlightSegment.fallback.distance.kilometres.to :nautical_miles
            end
          end
          
          ### Route inefficiency factor calculation
          # This calculation returns the `route inefficiency factor`. This is a measure of how much farther real world flights travel than the great circle distance between their origin and destination.
          # It accounts for factors like flight path routing around controlled airspace and circling while waiting for clearance to land.
          committee :route_inefficiency_factor do
            #### From country
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the `route inefficiency factor` for the [country](http://data.brighterplanet.com/countries) in which the flight occurs.
            quorum 'from country', :needs => :country, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:country].andand.flight_route_inefficiency_factor
            end
            
            #### Default
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the default `route inefficiency factor`.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do # **10%** based on [Kettunen et al. (2005)](http://www.atmseminar.org/seminarContent/seminar6/papers/p_055_MPM.pdf)
              Country.fallback.flight_route_inefficiency_factor
            end
          end
          
          ### Dogleg factor calculation
          # Returns the `dogleg factor`. This is a measure of how far out of the way the average layover is compared to a direct flight.
          committee :dogleg_factor do
            #### From segments per trip
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Assumes that each layover increases the total flight distance by **25%**.
            quorum 'from segments per trip', :needs => :segments_per_trip, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              1.25 ** (characteristics[:segments_per_trip] - 1)
            end
          end
          
          ### Distance estimate calculation (implied)
          # Returns the client-input `distance estimate` in *km*.
          
          ### Distance class calculation (implied)
          # Returns the client-input [distance class](http://data.brighterplanet.com/distance_classes).
          
          ### Fuel use coefficients calculation
          # Returns the `fuel use coefficients`. These are the coefficients of the third-order polynomial equation that describes aircraft fuel use.
          committee :fuel_use_coefficients do
            #### From aircraft
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
            
            #### From aircraft class
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [aircraft class](http://data.brighterplanet.com/aircraft_classes)' `fuel use coefficients`.
            quorum 'from aircraft class', :needs => :aircraft_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              aircraft_class = characteristics[:aircraft_class]
              FuelUseEquation.new aircraft_class.m3, aircraft_class.m2, aircraft_class.m1, aircraft_class.endpoint_fuel
            end
            
            #### From cohort
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average `fuel use coefficients` of the aircraft used by the `cohort` segments, weighted by their passengers.
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              flight_segments = characteristics[:cohort]
              
              passengers = flight_segments.inject(0) do |passengers, flight_segment|
                passengers + flight_segment.passengers
              end
              
              flight_segment_aircraft = flight_segments.inject({}) do |hsh, flight_segment|
                code = flight_segment.aircraft_type_code
                key = flight_segment.row_hash
                aircraft = Aircraft.find_by_aircraft_type_code code
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
            
            #### Default
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the default `fuel use coefficients`.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do # Calculates the average `fuel use coefficients` of the aircraft used by [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
              fallback = Aircraft.fallback
              if fallback
                FuelUseEquation.new fallback.m3, fallback.m2, fallback.m1, fallback.endpoint_fuel
              end
            end
          end
          
          ### Fuel type calculation
          # Returns the `fuel type`.
          committee :fuel_type do
            #### From client input (implied)
            # **Complies:** All
            #
            # Uses the client-input [fuel type](http://data.brighterplanet.com/fuel_types).
            
            #### Default
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Assumes the flight uses **Jet Fuel**.
            quorum 'default', :complies => [:ghg_protocol, :ico, :tcr] do
              FuelType.find_by_name 'Jet Fuel'
            end
          end
          
          ### Passengers calculation
          # Returns the number of `passengers`.
          committee :passengers do
            #### From seats and load factor
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
            #### From aircraft
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [aircraft](http://data.brighterplanet.com/aircraft)'s average number of `seats`.
            quorum 'from aircraft', :needs => :aircraft, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:aircraft].seats
            end
            
            #### From seats estimate
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Uses the client-input estimate of the number of `seats`.
            quorum 'from seats estimate', :needs => :seats_estimate, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:seats_estimate]
            end
            
            #### From cohort
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
            
            #### From aircraft class
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [aircraft class](http://data.brighterplanet.com/aircraft_classes)' average number of `seats`.
            quorum 'from aircraft class', :needs => :aircraft_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:aircraft_class].seats_before_type_cast
            end
            
            #### Default
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the default number of `seats`.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FlightSegment.fallback.seats_before_type_cast # need before_type_cast b/c seats is an integer but the fallback value is a float; Calculates the average number of `seats` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
            end
          end
          
          ### Seats estimate calculation (implied)
          # Returns the client-input `seats estimate`.
          
          ### Load factor calculation
          # Returns the `load factor`.
          # This is the portion of available seats that are occupied.
          committee :load_factor do
            #### From client input (implied)
            # **Complies:** All
            #
            # Uses the client-input `load factor`.
            
            #### From cohort
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average `load factor` of the `cohort` segments, weighted by their passengers.
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:cohort].weighted_average(:load_factor, :weighted_by => :passengers)
            end
            
            #### Default
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the default `load factor`.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FlightSegment.fallback.load_factor #Calculates the average `load factor` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
            end
          end
          
          ### Freight share calculation
          # Returns the `freight share`.
          # This is the percent of the total aircraft weight that is freight cargo and mail (as opposed to passengers and their baggage).
          committee :freight_share do
            #### From cohort
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Calculates the average `freight share` of the `cohort` segments, weighted by their passengers.
            quorum 'from cohort', :needs => :cohort, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:cohort].weighted_average(:freight_share, :weighted_by => :passengers)
            end
            
            #### Default
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the default `freight share`.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              FlightSegment.fallback.freight_share # Calculates the average `freight share` of [all segments in the T-100 database](http://data.brighterplanet.com/flight_segments), weighted by their passengers.
            end
          end
          
          ### Trips calculation
          # Returns the number of `trips`.
          # A one-way flight has one trip; a round-trip flight has two trips.
          committee :trips do
            #### From client input (implied)
            # **Complies:** All
            #
            # Uses the client-input number of `trips`.
            
            #### Default
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
            #### From seat class
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [seat class](http://data.brighterplanet.com/flight_seat_classes)' `seat class multiplier`.
            quorum 'from seat class', :needs => :seat_class, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:seat_class].multiplier
            end
            
            #### Default
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the default `seat class multiplier`.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do # **1**.
              FlightSeatClass.fallback.multiplier
            end
          end
          
          ### Seat class calculation (implied)
          # Returns the client-input [seat class](http://data.brighterplanet.com/seat_classes).
          
          ### Country calculation
          # Returns the [country](http://data.brighterplanet.com/countries) in which a flight occurs.
          committee :country do
            #### From client input (implied)
            # **Complies:** All
            #
            # Uses the client-input [country](http://data.brighterplanet.com/countries).
            
            #### From origin airport and destination airport
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
            #### From client input (implied)
            # **Complies:** All
            #
            # Uses the client-input [aircraft_class](http://data.brighterplanet.com/aircraft_classes).
            
            #### From aircraft
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Looks up the [aircraft](http://data.brighterplanet.com/aircraft)'s [aircraft_class](http://data.brighterplanet.com/aircraft_classes).
            quorum 'from aircraft', :needs => :aircraft, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:aircraft].aircraft_class
            end
          end
          
          ### Cohort calculation
          # Returns the `cohort`, which is a set of flight segment records in the [T-100 database](http://data.brighterplanet.com/flight_segments) that match certain client-input values.
          committee :cohort do
            #### From segments per trip and input
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
              if cohort.any?
                cohort
              else
                nil
              end
            end
          end
          
          ### Origin airport calculation (implied)
          # Returns the client-input [origin airport](http://data.brighterplanet.com/airports).
          
          ### Destination airport calculation (implied)
          # Returns the client-input [destination airport](http://data.brighterplanet.com/airports).
          
          ### Aircraft calculation (implied)
          # Returns the client-input type of [aircraft](http://data.brighterplanet.com/aircraft).
          
          ### Airline calculation (implied)
          # Returns the client-input [airline](http://data.brighterplanet.com/airlines) operating the flight.
          
          ### Segments per trip calculation
          # Returns the `segments per trip`.
          # Direct flights have a single segment per trip. Indirect flights with one or more layovers have two or more segments per trip.
          committee :segments_per_trip do
            #### From client input (implied)
            # **Complies:** All
            #
            # Uses the client-input `segments per trip`.
            
            #### Default
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Uses an average `segments per trip` of **1.67**, calculated from the [U.S. National Household Travel Survey](http://nhts.ornl.gov/).
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              1.67
            end
          end
          
          ### Date calculation
          # Returns the `date` on which the flight occured.
          committee :date do
            #### From client input (implied)
            # **Complies:** All
            #
            # Uses the client-input value for `date`.
            
            #### From timeframe
            # **Complies:** GHG Protocol, ISO-14064-1, Climate Registry Protocol
            #
            # Assumes the flight occured on the first day of the `timeframe`.
            quorum 'from timeframe', :complies => [:ghg_protocol, :iso, :tcr] do |characteristics, timeframe|
              timeframe.from
            end
          end
        end
      end
      
      class FuelUseEquation < Struct.new(:m3, :m2, :m1, :endpoint_fuel)
        def empty?
          m3.nil? and m2.nil? and m1.nil? and endpoint_fuel.nil?
        end
      end
    end
  end
end
