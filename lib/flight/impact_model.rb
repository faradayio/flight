# Copyright © 2010 Brighter Planet.
# See LICENSE for details.
# Contact Brighter Planet for dual-license arrangements.

## Flight impact model
# This model is used by the [Brighter Planet](http://brighterplanet.com) [CM1 web service](http://impact.brighterplanet.com) to calculate the per-passenger impacts of a flight, such as energy use and greenhouse gas emissions.

##### Timeframe
# The model calculates impacts that occured during a particular time period (`timeframe`).
# For example if the `timeframe` is February 2010, a flight that occurred (`date`) on February 15, 2010 will have impacts, but a flight that occurred on January 31, 2010 will have zero impacts.
#
# The default `timeframe` is the current calendar year.

##### Calculations
# The final impacts are the result of the calculations below. These are performed in reverse order, starting with the last calculation listed and finishing with the greenhouse gas emissions calculation.
#
# Each calculation listing shows:
#
# * value returned (*units of measurement*)
# * description of the value
# * calculation methods, listed from most to least preferred
#
# Some methods use `values` returned by prior calculations. If any of these `values` are unknown the method is skipped.
# If all the methods for a calculation are skipped, the value the calculation would return is unknown.

##### Standard compliance
# When compliance with a particular standard is requested, all methods that do not comply with that standard are ignored.
# Thus any `values` a method needs will have been calculated using a compliant method or will be unknown.
# To see which standards a method complies with, look at the `:complies =>` section of the code in the right column.
#
# Client input complies with all standards.

##### Collaboration
# Contributions to this impact model are actively encouraged and warmly welcomed. This library includes a comprehensive test suite to ensure that your changes do not cause regressions. All changes should include test coverage for new functionality. Please see [sniff](https://github.com/brighterplanet/sniff#readme), our emitter testing framework, for more information.

require 'cohort_analysis'
require 'flight/impact_model/fuel_use_equation'
require 'flight/impact_model/flight_segment_cohort'

module BrighterPlanet
  module Flight
    module ImpactModel
      def self.included(base)
        base.decide :impact, :with => :characteristics do
          # * * *
          
          #### Carbon (*kg CO<sub>2</sub>e*)
          # *The passenger's share of the flight's anthropogenic greenhouse emissions during `timeframe`.*
          committee :carbon do
            # Multiply `fuel use` (*l*) by `greenhouse gas emission factor` (*kg CO<sub>2</sub>e / l*) to give *kg CO<sub>2</sub>e*.
            quorum 'from fuel use and greenhouse gas emission factor', :needs => [:fuel_use, :ghg_emission_factor],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:fuel_use] * characteristics[:ghg_emission_factor]
            end
          end
          
          #### Greenhouse gas emission factor (*kg CO<sub>2</sub> / l*)
          # *An emission factor that includes the extra forcing effects of high-altitude emissions.*
          committee :ghg_emission_factor do
            # Multiply the [fuel](http://data.brighterplanet.com/fuels)'s co2 emission factor (*kg CO<sub>2</sub> / l*) by `aviation multiplier` to give *kg CO<sub>2</sub> / l*.
            quorum 'from fuel and aviation multiplier', :needs => [:fuel, :aviation_multiplier],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:fuel].co2_emission_factor * characteristics[:aviation_multiplier]
            end
          end
          
          #### Aviation multiplier
          # *A multiplier to account for the extra climate impact of greenhouse gas emissions high in the atmosphere.*
          committee :aviation_multiplier do
            # Use **2.0** after [Kollmuss and Crimmins (2009)](http://sei-us.org/publications/id/13).
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                2.0
            end
          end
          
          #### Energy (*MJ*)
          # *The passenger's share of the flight's energy consumption during `timeframe`.*
          committee :energy do
            # Multiply `fuel use` (*l*) by the [fuel](http://data.brighterplanet.com/fuels)'s `energy content` (*MJ / l*) to give *MJ*.
            quorum 'from fuel use and fuel', :needs => [:fuel_use, :fuel] do |characteristics|
              characteristics[:fuel_use] * characteristics[:fuel].energy_content
            end
          end
          
          #### Fuel use (*l*)
          # *The passenger's share of the flight's fuel use during `timeframe`.*
          committee :fuel_use do
            # Check whether `date` falls within `timeframe` - otherwise fuel use is zero.
            # Multiply `fuel per segment` (*kg*) by `segments per trip` and `trips` to give total fuel use (*kg*).
            # Multiply by (1 - `freight share`) to take out fuel attributed to cargo and mail, leaving fuel attributed to passengers and their baggage.
            # Divide by `passengers` and multiply by `seat class multiplier` to account for the portion of the cabin occupied by the passenger's seat.
            # Divide by the [fuel](http://data.brighterplanet.com/fuels)'s density (*kg / l*) to give *l*.
            quorum 'from fuel per segment, segments per trip, trips, freight_share, passengers, seat class multiplier, fuel, date, and timeframe',
              :needs => [:fuel_per_segment, :segments_per_trip, :trips, :freight_share, :passengers, :seat_class_multiplier, :fuel, :date],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics, timeframe|
=begin
  FIXME TODO date should already be coerced
=end
                date = characteristics[:date].is_a?(Date) ? characteristics[:date] : Date.parse(characteristics[:date].to_s)
                if timeframe.include? date
                  characteristics[:fuel_per_segment] * characteristics[:segments_per_trip] * characteristics[:trips] *
                    (1 - characteristics[:freight_share]) / characteristics[:passengers] * characteristics[:seat_class_multiplier] /
                    characteristics[:fuel].density
                else
                  0
                end
            end
          end
          
          #### Fuel per segment (*kg*)
          # *The fuel used by each nonstop segment of the flight.*
          committee :fuel_per_segment do
            # Fuel per segment = *m<sub>3</sub>d<sup>3</sup> + m<sub>2</sub>d<sup>2</sup> + m<sub>1</sub>d + b*
            # where *d* is `adjusted distance per segment` and *m<sub>3</sub>, m<sub>2</sub>, m<sub>1</sub>*, and *b* are the `fuel use coefficients`.
            quorum 'from adjusted distance per segment and fuel use coefficients', :needs => [:adjusted_distance_per_segment, :fuel_use_coefficients],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:fuel_use_coefficients].m3 * characteristics[:adjusted_distance_per_segment] ** 3 +
                  characteristics[:fuel_use_coefficients].m2 * characteristics[:adjusted_distance_per_segment] ** 2 +
                  characteristics[:fuel_use_coefficients].m1 * characteristics[:adjusted_distance_per_segment] +
                  characteristics[:fuel_use_coefficients].b
            end
          end
          
          #### Seat class multiplier
          # *A multiplier to account for the portion of cabin space occupied by the passenger's seat.*
          committee :seat_class_multiplier do
            # Use the `distance class seat class` multiplier.
            quorum 'from distance class seat class', :needs => :distance_class_seat_class,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:distance_class_seat_class].multiplier
            end
            
            # Otherwise use the average [distance class seat class](http://data.brighterplanet.com/flight_distance_class_seat_classes) multiplier.
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                FlightDistanceClassSeatClass.fallback.multiplier
            end
          end
          
          #### Distance class seat class
          # *The passenger's [distance class and seat class](http://data.brighterplanet.com/flight_distance_class_seat_classes).*
          committee :distance_class_seat_class do
            # Check whether the `distance class` and `seat class` combination matches any records in our database.
            # If it doesn't then we don't know `distance class seat class`.
            quorum 'from distance class and seat class', :needs => [:distance_class, :seat_class],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                FlightDistanceClassSeatClass.find_by_distance_class_name_and_seat_class_name(characteristics[:distance_class].name, characteristics[:seat_class].name)
            end
          end
          
          #### Distance class
          # *The flight's [distance class](http://data.brighterplanet.com/flight_distance_classes).*
          committee :distance_class do
            # Use client input, if available.
            
            # Otherwise look up the [distance class](http://data.brighterplanet.com/flight_distance_classes) that corresponds to `adjusted distance per segment`.
            quorum 'from adjusted distance per segment', :needs => :adjusted_distance_per_segment,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                FlightDistanceClass.find_by_distance(characteristics[:adjusted_distance_per_segment].nautical_miles.to :kilometres)
            end
          end
          
          #### Seat class
          # *The passenger's [seat class](http://data.brighterplanet.com/flight_seat_classes).*
          #
          # Use client input if available.
          
          #### Adjusted distance per segment (*nautical miles*)
          # *The distance of each nonstop segment of the flight.*
          committee :adjusted_distance_per_segment do
            # Divide `adjusted distance` (*nautical miles*) by `segments per trip` to give *nautical miles*.
            quorum 'from adjusted distance and segments per trip', :needs => [:adjusted_distance, :segments_per_trip],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:adjusted_distance] / characteristics[:segments_per_trip]
            end
          end
          
          #### Adjusted distance (*nautical miles*)
          # *The flight's distance accounting for factors that increase the actual distance traveled by real world flights.*
          committee :adjusted_distance do
            # Multiply `distance` (*nautical miles*) by `route inefficiency factor` and `dogleg factor` to give *nautical miles*.
            quorum 'from distance, route inefficiency factor, and dogleg factor', :needs => [:distance, :route_inefficiency_factor, :dogleg_factor],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:distance] * characteristics[:route_inefficiency_factor] * characteristics[:dogleg_factor]
            end
          end
          
          #### Distance (*nautical miles*)
          # *The flight's base distance.*
          committee :distance do
            # Calculate the great circle distance between the `origin airport` and `destination airport` (*km*) and convert to *nautical miles*.
            quorum 'from airports', :needs => [:origin_airport, :destination_airport],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:origin_airport].distance_to(characteristics[:destination_airport], :units => :kms).kilometres.to :nautical_miles
            end
            
            # Otherwise convert `distance estimate`(*km*) to *nautical miles*.
            quorum 'from distance estimate', :needs => :distance_estimate,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:distance_estimate].kilometres.to :nautical_miles
            end
            
            # Otherwise convert the `distance class` distance (*km*) to *nautical miles*.
            quorum 'from distance class', :needs => :distance_class,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:distance_class].distance.kilometres.to :nautical_miles
            end
            
=begin
  This should not be prioritized over distance estimate or distance class because cohort here never has both airports
=end
            # Otherwise calculate the average distance of the `cohort` segments, weighted by passengers, (*km*) and convert to *nautical miles*.
            quorum 'from cohort', :needs => :cohort do |characteristics|
              distance = characteristics[:cohort].weighted_average(:distance, :weighted_by => :passengers).kilometres.to :nautical_miles
=begin
  Need to check distance > 0 because some flight segments have 0 for distance
=end
              distance > 0 ? distance : nil
            end
            
            # Otherwise calculate the average `distance` of [all flight segments in our database](http://data.brighterplanet.com/flight_segments), weighted by passengers, (*km*) and convert to *nautical miles*.
            quorum 'default' do
              FlightSegment.fallback.distance.kilometres.to :nautical_miles
            end
          end
          
          #### Route inefficiency factor
          # *A multiplier to account for factors like flight path routing around controlled airspace and circling while waiting for clearance to land.*
          committee :route_inefficiency_factor do
            # Use the `country` route inefficiency factor.
            quorum 'from country', :needs => :country,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:country].flight_route_inefficiency_factor
            end
            
            # Otherwise use the [global average](http://data.brighterplanet.com/countries) `route inefficiency factor`.
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                Country.fallback.flight_route_inefficiency_factor
            end
          end
          
          #### Dogleg factor
          # *A multiplier that represents how 'out of the way' connecting airports are compared to a nonstop flight.*
          committee :dogleg_factor do
            # Assume that each connection increases the total flight distance by **25%**.
            quorum 'from segments per trip', :needs => :segments_per_trip,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                1.25 ** (characteristics[:segments_per_trip] - 1)
            end
          end
          
          #### Distance estimate (*km*)
          # *The client's estimate of the flight's distance.*
          #
          # Use client input, if available.
          
          #### Distance class
          # *The flight's [distance class](http://data.brighterplanet.com/flight_distance_classes).*
          #
          # Use client input, if available.
          
          #### Fuel use coefficients
          # *The coefficients of a third-order polynomial equation that describes aircraft fuel use.*
          committee :fuel_use_coefficients do
            quorum 'from cohort', :needs => :cohort,
              # Calculate the average fuel use coefficients of the `cohort` aircraft, weighted by the passengers carried by each of those aircraft:
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                FuelUseEquation.from_flight_segment_cohort characteristics[:cohort]
            end
            
            # Otherwise use the `aircraft` fuel use coefficients.
            quorum 'from aircraft', :needs => :aircraft,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                FuelUseEquation.from_coefficients characteristics[:aircraft].m3, characteristics[:aircraft].m2, characteristics[:aircraft].m1, characteristics[:aircraft].b
            end
            
            # Otherwise calculate the average fuel use coefficients of all [aircraft](http://data.brighterplanet.com/aircraft), weighted by passengers.
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                FuelUseEquation.from_coefficients Aircraft.fallback.m3, Aircraft.fallback.m2, Aircraft.fallback.m1, Aircraft.fallback.b
            end
          end
          
          #### Fuel
          # *The type of [fuel](http://data.brighterplanet.com/fuels) used by the aircraft.*
          committee :fuel do
            # Use client input, if available.
            
            # Otherwise assume the flight uses **Jet Fuel**.
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                Fuel.find_by_name 'Jet Fuel'
            end
          end
          
          #### Passengers
          # *The number of passengers on the flight.*
          committee :passengers do
            # Multiply `seats` by `load factor` and round to the nearest whole number.
            quorum 'from seats and load factor', :needs => [:seats, :load_factor],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                (characteristics[:seats] * characteristics[:load_factor]).round
            end
          end
          
          #### Seats
          # *The number of seats on the aircraft.*
          committee :seats do
            # Uses client input, if available.
            
            # Otherwise calculate the average seats of the `cohort` segments, weighted by passengers.
            quorum 'from cohort', :needs => :cohort,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:cohort].weighted_average(:seats_per_flight, :weighted_by => :passengers)
            end
            
            # Otherwise use the `aircraft` average number of seats.
            quorum 'from aircraft', :needs => :aircraft,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:aircraft].seats
            end
            
            # Otherwise calculate the average seats of [all flight segments in our database](http://data.brighterplanet.com/flight_segments), weighted by passengers.
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                FlightSegment.fallback.seats_per_flight
            end
          end
          
          #### Load factor
          # *The portion of available seats that are occupied.*
          committee :load_factor do
            # Uses client input, if available.
            
            # Otherwise calculate the average load factor of the `cohort` segments, weighted by passengers.
            quorum 'from cohort', :needs => :cohort,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                load_factor = characteristics[:cohort].weighted_average(:load_factor, :weighted_by => :passengers)
            end
            
            # Otherwise calculate the average load factor of [all flight segments in our database](http://data.brighterplanet.com/flight_segments), weighted by passengers.
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                FlightSegment.fallback.load_factor
            end
          end
          
          #### Freight share
          # *The percent of the total aircraft weight that is cargo and mail, as opposed to passengers and their baggage.*
          committee :freight_share do
            # Calculate the average freight share of the `cohort` segments, weighted by passengers.
            quorum 'from cohort', :needs => :cohort,
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                characteristics[:cohort].weighted_average(:freight_share, :weighted_by => :passengers)
            end
            
            # Otherwise calculate the average freight share of [all flight segments in our database](http://data.brighterplanet.com/flight_segments), weighted by passengers.
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                FlightSegment.fallback.freight_share
            end
          end
          
          #### Trips
          # *A one-way flight has one trip; a round-trip flight has two trips.*
          committee :trips do
            # Uses client input, if available.
            
            # Otherwise use an average of **1.7**, calculated from the [BTS Origin and Destination Survey](https://spreadsheets.google.com/pub?key=0Anc8M0qoN5VidC1ESzRRb21zaVRodkN6TF95M3JQeUE&hl=en&output=html).
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                1.7
            end
          end
          
          #### Country
          # *The [country](http://data.brighterplanet.com/countries) in which the flight occured.*
          committee :country do
            # If the flight's `origin airport` and `destination airport` are within the same country, use that country.
            quorum 'from origin airport and destination airport', :needs => [:origin_airport, :destination_airport],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
                if characteristics[:origin_airport].country == characteristics[:destination_airport].country
                  characteristics[:origin_airport].country
                end
            end
          end
          
          #### Cohort
          # *A set of flight segment records in [our database](http://data.brighterplanet.com/flight_segments) that match certain client-input values.*
          committee :cohort do
            # If the client specified the id of a single flight segment in our database, use that flight segment.
            quorum 'from row_hash', :needs => [:flight_segment_row_hash] do |characteristics|
              FlightSegment.where(:row_hash => characteristics[:flight_segment_row_hash].value)
            end
            
            # Otherwise assemble a cohort based on whatever client inputs are available:
            quorum 'from segments per trip and input',
              :needs => :segments_per_trip, :appreciates => [:origin_airport, :destination_airport, :aircraft, :airline, :date],
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics|
              FlightSegmentCohort.from_characteristics characteristics
            end
          end
          
          #### Origin airport
          # *The flight's [origin airport](http://data.brighterplanet.com/airports).*
          #
          # Use client input, if available.
          
          #### Destination airport
          # *The flight's [destination airport](http://data.brighterplanet.com/airports).*
          #
          # Use client input, if available.
          
          #### Aircraft
          # *The flight's [aircraft](http://data.brighterplanet.com/aircraft).*
          #
          # Use client input, if available.
          
          #### Airline
          # *The [airline](http://data.brighterplanet.com/airlines) that operates the flight. For codeshare flights this may be different than the ticketing airline.*
          #
          # Use client input, if available.
          
          #### Segments per trip
          # *The number of nonstop flight segments. A nonstop flight has 1 segment per trip (e.g. JFK to SFO); a connecting flight has 2 or more segments (e.g. JFK to SFO via ORD).*
          committee :segments_per_trip do
            # Use client input, if available.
            
            # Otherwise use an average of **1.68**, calculated from the [BTS Origin and Destination Survey](https://spreadsheets.google.com/pub?key=0Anc8M0qoN5VidC1ESzRRb21zaVRodkN6TF95M3JQeUE&hl=en&output=html).
            quorum 'default',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do
                1.68
            end
          end
          
          #### Date (*date*)
          # *The day the flight occurred.*
          committee :date do
            # Use client input, if available.
            
            # Otherwise assume the flight occurred on the first day of `timeframe`.
            quorum 'from timeframe',
              :complies => [:ghg_protocol_scope_3, :iso, :tcr] do |characteristics, timeframe|
                timeframe.from
            end
          end
        end
      end
    end
  end
end
