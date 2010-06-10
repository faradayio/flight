module BrighterPlanet
  module Flight
    def self.included(base)
      base.extend ::Leap::Subject
      base.decide :emission, :with => :characteristics do
        committee :emission do
          quorum 'from fuel and passengers with coefficients', :needs => [:fuel, :passengers, :seat_class_multiplier, :emission_factor, :radiative_forcing_index, :freight_share, :date] do |characteristics, timeframe|
            if timeframe.include? characteristics[:date]
              #(                                               kg fuel                                        ) * (                                              kg CO2 / kg fuel                                                     ) = kg CO2
              (characteristics[:fuel] / characteristics[:passengers] * characteristics[:seat_class_multiplier]) * characteristics[:emission_factor] * characteristics[:radiative_forcing_index] * (1 - characteristics[:freight_share])
            else
              0
            end
          end
          
          quorum 'default' do
            raise "The emission committee's default quorum should never be called"
          end
        end
        
        committee :fuel do # returns kg fuel
          quorum 'from fuel per segment and emplanements and trips', :needs => [:fuel_per_segment, :emplanements_per_trip, :trips] do |characteristics|
            characteristics[:fuel_per_segment] * characteristics[:emplanements_per_trip].to_f * characteristics[:trips].to_f
          end
        end
        
        committee :fuel_per_segment do # returns kg fuel
          quorum 'from adjusted distance and fuel use formula and emplanements and trips', :needs => [:adjusted_distance_per_segment, :fuel_use_coefficients, :endpoint_fuel] do |characteristics|
            characteristics[:fuel_use_coefficients][:m3].to_f * characteristics[:adjusted_distance_per_segment].to_f ** 3 +
              characteristics[:fuel_use_coefficients][:m2].to_f * characteristics[:adjusted_distance_per_segment].to_f ** 2 +
              characteristics[:fuel_use_coefficients][:m1].to_f * characteristics[:adjusted_distance_per_segment].to_f +
              characteristics[:endpoint_fuel].to_f
          end
        end
        
        committee :adjusted_distance_per_segment do
          quorum 'from adjusted distance and emplanements', :needs => [:adjusted_distance, :emplanements_per_trip] do |characteristics|
            characteristics[:adjusted_distance] / characteristics[:emplanements_per_trip]
          end
        end
        
        committee :endpoint_fuel do
          quorum 'from aircraft', :needs => :aircraft do |characteristics|
            characteristics[:aircraft].endpoint_fuel
          end
          
          quorum 'from aircraft class', :needs => :aircraft_class do |characteristics|
            characteristics[:aircraft_class].endpoint_fuel
          end
          
          quorum 'default' do
            Aircraft.fallback.endpoint_fuel
          end
        end
        
        committee :fuel_use_coefficients do
          quorum 'from aircraft', :needs => :aircraft do |characteristics|
            characteristics[:aircraft].attributes.symbolize_keys.slice(:m1, :m2, :m3)
          end
          
          quorum 'from aircraft class', :needs => :aircraft_class do |characteristics|
            characteristics[:aircraft_class].attributes.symbolize_keys.slice(:m1, :m2, :m3)
          end
          
          quorum 'default' do
            Aircraft.fallback.attributes.symbolize_keys.slice(:m1, :m2, :m3)
          end
        end
        
        committee :passengers do
          quorum 'from seats and load factor', :needs => [:seats, :load_factor] do |characteristics|
            (characteristics[:seats] * characteristics[:load_factor]).round
          end
        end
        
        committee :seats do
    # leaving this here to explain how someday we might lookup seat count based on both airline AND aircraft
    #SE      quorum 'from_airline_and_aircraft', :needs => [:airline, :aircraft] do |characteristics, timeframe|
    #SE        if aircraft = AirlineAircraft.memoized_find_by_airline_id_and_aircraft_id(characteristics[:airline].id, characteristics[:aircraft].id)
    #SE          aircraft.seats
    #SE        end
    #SE      end
          
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
            characteristics[:aircraft_class].seats
          end
          
          quorum 'default' do
            FlightSegment.fallback.seats
          end
        end
        
        committee :load_factor do
          quorum 'from cohort', :needs => :cohort do |characteristics|
            characteristics[:cohort].weighted_average(:load_factor, :weighted_by => :passengers)
          end
    
          quorum 'default' do
            ::Flight.fallback.load_factor
          end
        end
        
        committee :adjusted_distance do # returns nautical miles
          quorum 'from distance', :needs => [:distance, :emplanements_per_trip] do |characteristics|
            characteristics[:distance] * research(:route_inefficiency_factor) * ( research(:dogleg_factor) ** (characteristics[:emplanements_per_trip] - 1) )
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
            ::Flight.fallback.distance_estimate.kilometres.to :nautical_miles
          end
        end
        
        committee :emplanements_per_trip do # per trip
          quorum 'default' do
            ::Flight.fallback.emplanements_per_trip_before_type_cast
          end
        end
        
        committee :radiative_forcing_index do
          quorum 'from fuel type', :needs => :fuel_type do |characteristics|
            characteristics[:fuel_type].radiative_forcing_index
          end
        end
        
        committee :emission_factor do # returns kg CO2 / kg fuel
          quorum 'from fuel type', :needs => :fuel_type do |characteristics|
            #(            kg CO2 / litres fuel        ) * (                 litres fuel / kg fuel                      )
            characteristics[:fuel_type].emission_factor * ( 1 / characteristics[:fuel_type].density).gallons.to(:litres)
          end
        end
        
        committee :fuel_type do
          quorum 'default' do
            FlightFuelType.fallback
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
            ::Flight.fallback.trips_before_type_cast
          end
        end
        
        committee :domesticity do
          quorum 'from airports', :needs => [:origin_airport, :destination_airport] do |characteristics|
            if [characteristics[:origin_airport], characteristics[:destination_airport]].all?(&:united_states?)
              FlightDomesticity.find_by_name('domestic')
            elsif [characteristics[:origin_airport], characteristics[:destination_airport]].any?(&:united_states?)
              FlightDomesticity.find_by_name('international')
            end
          end
          
          quorum 'from origin', :needs => :origin_airport do |characteristics|
            if characteristics[:origin_airport].all_flights_from_here_domestic?
              FlightDomesticity.find_by_name('domestic')
            end
          end
          
          quorum 'from destination', :needs => :destination_airport do |characteristics|
            if characteristics[:destination_airport].all_flights_to_here_domestic?
              FlightDomesticity.find_by_name('domestic')
            end
          end
          
          quorum 'from airline', :needs => :airline do |characteristics|
            if characteristics[:airline].all_flights_domestic?
              FlightDomesticity.find_by_name('domestic')
            end
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
        
        committee :date do
          quorum 'from creation date', :needs => :creation_date do |characteristics|
            characteristics[:creation_date]
          end
          
          quorum 'from timeframe' do |characteristics, timeframe|
            timeframe.from
          end
        end
        
        committee :cohort do
          quorum 'from t100', :appreciates => FlightSegment::INPUT_CHARACTERISTICS do |characteristics|
            cohort = FlightSegment.big_cohort characteristics
            if cohort.any?
              cohort
            else
              nil
            end
          end
        end
      end
    end
  end
end