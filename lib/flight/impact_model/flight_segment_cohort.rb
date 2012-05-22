module BrighterPlanet
  module Flight
    module ImpactModel
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
        attr_reader :where_sql
        attr_reader :table_name

        # We pull values out of charisma curations here
        # TODO: don't make up for charisma's probs
        def initialize(characteristics)
          @relation_mutex = ::Mutex.new
          @characteristics = characteristics.inject({}) do |memo, (k, v)|
            memo[k] = v.respond_to?(:value) ? v.value : v
            memo
          end
        end
        
        def valid?
          characteristics[:segments_per_trip] == 1 and
          characteristics[:date].present? and
          relation.any?
        end
        
        def weighted_average(*args)
          relation.weighted_average(*args)
        end
        
        def to_sql
          FlightSegment.where(where_sql).to_sql
        end
        
        def count
          relation.count
        end

        def as_json(*)
          { :members => count, :sql => to_sql }
        end

        def cleanup
          ActiveRecord::Base.connection.execute %{
            DROP TABLE #{table_name}
          }
        end
        
        private
        
        def relation
          return @relation if @calculated == true
          @relation_mutex.synchronize do
            return @relation if @calculated == true
            @calculated = true
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

                provided_characteristics = {}

=begin
NOTE: It's possible that the origin/destination pair won't appear in our database and we'll end up using a
cohort based just on origin. If that happens, even if the origin is not in the US we still don't want to use
origin airport city, because we know the flight was going to the US and ICAO segments never touch the US.
=end
                provided_characteristics[:origin_airport_iata_code] = characteristics[:origin_airport].iata_code
                provided_characteristics[:destination_airport_iata_code] = characteristics[:destination_airport].iata_code

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

                provided_characteristics = {}
                provided_characteristics[:origin_airport_city] = characteristics[:origin_airport].city
                provided_characteristics[:destination_airport_city] = characteristics[:destination_airport].city
              end

              # - Also use `aircraft` and `airline` if they're available
              if characteristics[:aircraft].present?
                provided_characteristics[:aircraft_description] = characteristics[:aircraft].flight_segments_foreign_keys
              end

              if characteristics[:airline].present?
                provided_characteristics[:airline_name] = characteristics[:airline].name
              end

              # - Assemble a cohort by starting with all flight segments in the relevant years. Select only the
              # segments that match the characteristics we've decided to use. If no segments match all the
              # characteristics, drop the last characteristic (initially `airline`) and try again. Continue until
              # we have some segments or we've dropped all the characteristics.
              priority = [:origin_airport_iata_code, :destination_airport_iata_code, :origin_airport_city, :destination_airport_city, :aircraft_description, :airline_name]
              cohort_constraint = FlightSegment.cohort_constraint(provided_characteristics, :strategy => :strict, :priority => priority)

              fs = FlightSegment.arel_table
              fs_relation = FlightSegment.where(fs[:year].in(relevant_years).and(fs[:passengers].gt(0)).and(cohort_constraint))
            # If we don't have both `origin airport` and `destination airport`:
            else
              # Restrict the cohort to flight segments that occurred the same year as the flight or the previous three years.
              # (We need to include the previous three years because 2009 is the most recent year for which we have complete ICAO data.)
              relevant_years = [date.year - 3, date.year - 2, date.year - 1, date.year]

              provided_characteristics = {}

              # - Use airport iata codes to assemble a cohort of BTS flight segments
              if characteristics[:origin_airport].present?
                provided_characteristics[:origin_airport_iata_code] = characteristics[:origin_airport].iata_code
              end

              if characteristics[:destination_airport].present?
                provided_characteristics[:destination_airport_iata_code] = characteristics[:destination_airport].iata_code
              end

              # - Also use `aircraft` and `airline` if they're available.
              if characteristics[:aircraft].present?
                provided_characteristics[:aircraft_description] = characteristics[:aircraft].flight_segments_foreign_keys
              end

              if characteristics[:airline].present?
                provided_characteristics[:airline_name] = characteristics[:airline].name
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
              priority = [:origin_airport_iata_code, :destination_airport_iata_code, :aircraft_description, :airline_name]
              bts_cohort_constraint = FlightSegment.cohort_constraint(provided_characteristics, :strategy => :strict, :priority => priority)

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
              provided_characteristics = {}
              if characteristics[:origin_airport].present?
                provided_characteristics[:origin_airport_city] = characteristics[:origin_airport].city
              end

              if characteristics[:destination_airport].present?
                provided_characteristics[:destination_airport_city] = characteristics[:destination_airport].city
              end

              # - Also use `aircraft` and `airline` if they're available.
              if characteristics[:aircraft].present?
                provided_characteristics[:aircraft_description] = characteristics[:aircraft].flight_segments_foreign_keys
              end

              if characteristics[:airline].present?
                provided_characteristics[:airline_name] = characteristics[:airline].name
              end

              # - Assemble a cohort by starting with all flight segments in the relevant years. Select only the
              # segments that match the characteristics we've decided to use. If no segments match all the
              # characteristics, drop the last characteristic (initially `airline`) and try again. Continue until
              # we have some segments or we've dropped all the characteristics.
              priority = [:origin_airport_city, :destination_airport_city, :aircraft_description, :airline_name]
              icao_cohort_constraint = FlightSegment.cohort_constraint(provided_characteristics, :strategy => :strict, :priority => priority)
              
              # - Combine the two cohorts, making sure to restrict to relevant years and segments with passengers
              fs = FlightSegment.arel_table
              fs_relation = FlightSegment.where(fs[:year].in(relevant_years).and(fs[:passengers].gt(0)).and(icao_cohort_constraint.or(bts_cohort_constraint)))
            end
            @where_sql = fs_relation.where_sql
            c = FlightSegment.connection
            @table_name = "flight_segment_cohort_#{::Kernel.rand(1e11)}"
            populated = false
            if c.adapter_name =~ /sqlite/i
              populated = true
              c.execute %{
                CREATE TEMPORARY TABLE #{table_name} AS
                SELECT * FROM #{FlightSegment.quoted_table_name} #{fs_relation.where_sql}
              }
            else
              c.execute %{
                CREATE TEMPORARY TABLE #{table_name} LIKE #{FlightSegment.quoted_table_name}
              }
            end
            if c.adapter_name =~ /mysql/i
              c.execute %{
                ALTER TABLE #{table_name} ENGINE=MEMORY
              }
            end
            unless populated
              c.execute %{
                INSERT INTO #{table_name}
                SELECT * FROM #{FlightSegment.quoted_table_name} #{fs_relation.where_sql}
              }
            end
            if c.adapter_name =~ /mysql/i
              c.execute %{
                ANALYZE TABLE #{table_name}
              }
            end
            @relation = ActiveRecord::Relation.new FlightSegment, Arel::Table.new(table_name)
          end
        end
      end
    end
  end
end
