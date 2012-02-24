module BrighterPlanet
  module Flight
    module ImpactModel
      # Acts like an cohort/relation for these methods:
      # * where_sql
      # * weighted_average
      # * to_sql
      # * count
      # Does not attempt to delegate/forward to maintain simplicity.
      class FlightSegmentCohort
        class << self
          def from_characteristics(characteristics)
            flight_segment_cohort = new characteristics
            if flight_segment_cohort.valid?
              flight_segment_cohort
            else
              nil
            end
          end
        end
        
        attr_reader :characteristics
        
        # We pull values out of charisma curations here
        # TODO: don't make up for charisma's probs
        def initialize(characteristics)
          @characteristics = characteristics.inject({}) do |memo, (k, v)|
            memo[k] = v.respond_to?(:value) ? v.value : value
            memo
          end
        end
        
        def valid?
          characteristics[:segments_per_trip] == 1 and cohort.any?
        end
        
        def where_sql
          cohort.where_sql
        end
        
        def weighted_average(*args)
          cohort.weighted_average(*args)
        end
        
        def to_sql
          cohort.to_sql
        end
        
        def count
          cohort.count
        end
        
        private
        
        def cohort
          return @cohort if @cohort
          
          provided_characteristics = []
=begin
FIXME TODO date should already be coerced
=end
          date = characteristics[:date].is_a?(Date) ? characteristics[:date] : Date.parse(characteristics[:date].to_s)

          # If we have both `origin airport` and `destination airport`:
          if characteristics[:origin_airport].present? and characteristics[:destination_airport].present?
            # - If either airport is in the US, use airport iata codes to assemble a cohort of BTS flight segments
            if characteristics[:origin_airport].country_iso_3166_code == "US" or characteristics[:destination_airport].country_iso_3166_code == "US"
              # Restrict the cohort to flight segments that occurred the same year as the flight or the previous year.
              # (We need to include the previous year because BTS flight segment data lags by 6 months.)
              relevant_years = [date.year - 1, date.year]

=begin
NOTE: It's possible that the origin/destination pair won't appear in our database and we'll end up using a
cohort based just on origin. If that happens, even if the origin is not in the US we still don't want to use
origin airport city, because we know the flight was going to the US and ICAO segments never touch the US.
=end
              provided_characteristics.push [:origin_airport_iata_code, characteristics[:origin_airport].iata_code]
              provided_characteristics.push [:destination_airport_iata_code, characteristics[:destination_airport].iata_code]

            # - If neither airport is in the US, use airport cities to assemble a cohort of ICAO flight segments
=begin
FIXME TODO deal with cities in multiple countries that share a name
Tried pushing country, which works on a flight from Mexico City to Barcelona, Spain because it does
not include flights to Barcelona, Venezuela BUT it doesn't work if we're trying to go from Montreal
end up with flights to London, United Kingdom. Also pushing country breaks addition of cohorts - all 'AND'
statements get changed to 'OR' so you end up with all flights to that country
e.g. WHERE origin_airport_iata_code = 'JFK' OR origin_country_iso_3166_code = 'US'
=end
            else
              # Restrict the cohort to flight segments that occurred the same year as the flight or the previous three years.
              # (We need to include the previous three years because 2009 is the most recent year for which we have complete ICAO data.)
              relevant_years = [date.year - 3, date.year - 2, date.year - 1, date.year]

              provided_characteristics.push [:origin_airport_city, characteristics[:origin_airport].city]
              provided_characteristics.push [:destination_airport_city, characteristics[:destination_airport].city]
            end

            # - Also use `aircraft` and `airline` if they're available
            if characteristics[:aircraft].present?
              provided_characteristics.push [:aircraft_description, characteristics[:aircraft].flight_segments_foreign_keys]
            end

            if characteristics[:airline].present?
              provided_characteristics.push [:airline_name, characteristics[:airline].name]
            end

            # - Assemble a cohort by starting with all flight segments in the relevant years. Select only the
            # segments that match the characteristics we've decided to use. If no segments match all the
            # characteristics, drop the last characteristic (initially `airline`) and try again. Continue until
            # we have some segments or we've dropped all the characteristics.
            @cohort = FlightSegment.where(:year => relevant_years).where("passengers > 0").strict_cohort(*provided_characteristics)
=begin
TODO: make 'passengers > 0' a constraint once cohort_scope supports non-hash constraints
=end
          # If we don't have both `origin airport` and `destination airport`:
          else
            # Restrict the cohort to flight segments that occurred the same year as the flight or the previous three years.
            # (We need to include the previous three years because 2009 is the most recent year for which we have complete ICAO data.)
            relevant_years = [date.year - 3, date.year - 2, date.year - 1, date.year]

            # - Use airport iata codes to assemble a cohort of BTS flight segments
            if characteristics[:origin_airport].present?
              provided_characteristics.push [:origin_airport_iata_code, characteristics[:origin_airport].iata_code]
            end

            if characteristics[:destination_airport].present?
              provided_characteristics.push [:destination_airport_iata_code, characteristics[:destination_airport].iata_code]
            end

            # - Also use `aircraft` and `airline` if they're available.
            if characteristics[:aircraft].present?
              provided_characteristics.push [:aircraft_description, characteristics[:aircraft].flight_segments_foreign_keys]
            end

            if characteristics[:airline].present?
              provided_characteristics.push [:airline_name, characteristics[:airline].name]
            end

=begin
Note: can't use where conditions here e.g. where(:year => relevant_years) because when we combine the cohorts
all AND become OR so we get WHERE year IN (*relevant_years*) OR *other conditions* which returns every
flight segment in the relevant_years
=end
            # - Assemble a cohort by starting with all flight segments in the relevant years. Select only the
            # segments that match the characteristics we've decided to use. If no segments match all the
            # characteristics, drop the last characteristic (initially `airline`) and try again. Continue until
            # we have some segments or we've dropped all the characteristics.
            bts_cohort = FlightSegment.strict_cohort(*provided_characteristics)

            # - Then use airport city to assemble a cohort of ICAO flight segments
=begin
FIXME TODO: deal with cities in multiple countries that share a name
Tried pushing country, which works on a flight from Mexico City to Barcelona, Spain because it does
not include flights to Barcelona, Venezuela BUT it doesn't work if we're trying to go from Montreal
to London, Canada because there are no nonstop flights to London, Canada so country gets dropped and we
end up with flights to London, United Kingdom. Also pushing country breaks addition of cohorts - all 'AND'
statements get changed to 'OR' so you end up with all flights to that country
e.g. WHERE origin_airport_iata_code = 'JFK' OR origin_country_iso_3166_code = 'US'
=end
            provided_characteristics = []
            if characteristics[:origin_airport].present?
              provided_characteristics.push [:origin_airport_city, characteristics[:origin_airport].city]
            end

            if characteristics[:destination_airport].present?
              provided_characteristics.push [:destination_airport_city, characteristics[:destination_airport].city]
            end

            # - Also use `aircraft` and `airline` if they're available.
            if characteristics[:aircraft].present?
              provided_characteristics.push [:aircraft_description, characteristics[:aircraft].flight_segments_foreign_keys]
            end

            if characteristics[:airline].present?
              provided_characteristics.push [:airline_name, characteristics[:airline].name]
            end

            # - Assemble a cohort by starting with all flight segments in the relevant years. Select only the
            # segments that match the characteristics we've decided to use. If no segments match all the
            # characteristics, drop the last characteristic (initially `airline`) and try again. Continue until
            # we have some segments or we've dropped all the characteristics.
            icao_cohort = FlightSegment.strict_cohort(*provided_characteristics)

            # - Combine the two cohorts, making sure to restrict to relevant years and segments with passengers
=begin
Note: cohort_scope 0.2.1 provides cohort + cohort => cohort; cohort.where() => relation; relation.to_cohort => cohort
=end
            @cohort = (bts_cohort + icao_cohort).where(:year => relevant_years).where("passengers > 0").to_cohort
          end
        end
      end
    end
  end
end
