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
        attr_reader :subselect_sql
        attr_reader :table_name
        
        # We pull values out of charisma curations here
        # TODO: don't make up for charisma's probs
        def initialize(characteristics)
          @table_mutex = ::Mutex.new
          @characteristics = characteristics.inject({}) do |memo, (k, v)|
            if vv = v.respond_to?(:value) ? v.value : v
              memo[k] = vv
            end
            memo
          end
        end
        
        def valid?
          characteristics[:segments_per_trip] == 1 and
          characteristics[:date].present? and
          provided.any? and
          count > 0
        end
        
        def weighted_average(*args)
          table.weighted_average(*args)
        end
        
        def to_sql
          subselect_sql
        end
        
        def count
          count_table = table.dup
          count_table.projections = [Arel.sql('COUNT(*)')]
          FlightSegment.connection.select_value count_table.to_sql
        end

        def as_json(*)
          { :members => count, :sql => to_sql }
        end

        def cleanup
          FlightSegment.connection.execute %{
            DROP TABLE #{table_name}
          }
        end
        
        private

        def provided
          {
            :aircraft_description => characteristics[:aircraft].try(:flight_segments_foreign_keys),
            :airline_name => characteristics[:airline].try(:name),
            :origin_airport_iata_code => origin_airport.try(:iata_code),
            :origin_airport_city => origin_airport.try(:city),
            :destination_airport_iata_code => destination_airport.try(:iata_code),
            :destination_airport_city => destination_airport.try(:city),
          }.select do |k, v|
            v.present?
          end
        end

        def relevant_years
          date = characteristics[:date].is_a?(Date) ? characteristics[:date] : Date.parse(characteristics[:date].to_s)
          if covered_by_bts?
            # Restrict the cohort to flight segments that occurred the same year as the flight or the previous year.
            # (We need to include the previous year because BTS flight segment data lags by 6 months.)
            [date.year - 1, date.year]
          else
            # Restrict the cohort to flight segments that occurred the same year as the flight or the previous three years.
            # (We need to include the previous three years because 2009 is the most recent year for which we have complete ICAO data.)
            [date.year - 3, date.year - 2, date.year - 1, date.year]
          end
        end

        def covered_by_bts?
          origin_airport.try(:country_iso_3166_code) == "US" or destination_airport.try(:country_iso_3166_code) == "US"
        end

        def cohort_from_source(source, priority)
          fs = FlightSegment.arel_table
          relation = FlightSegment.where fs[:source].eq(source).and(fs[:year].in(relevant_years).and(fs[:passengers].gt(0)))
          relation.cohort(provided.slice(*priority), :strategy => :strict, :priority => priority).project(Arel.star)
        end

        # Assemble a cohort by starting with all flight segments in the relevant years. Select only the
        # segments that match the characteristics we've decided to use. If no segments match all the
        # characteristics, drop the last characteristic (initially `airline`) and try again. Continue until
        # we have some segments or we've dropped all the characteristics.
        def bts_cohort
          cohort_from_source 'BTS T100', [:origin_airport_iata_code, :destination_airport_iata_code, :aircraft_description, :airline_name]
        end

        # FIXME TODO deal with cities in multiple countries that share a name
        # Tried pushing country, which works on a flight from Mexico City to Barcelona, Spain because it does
        # not include flights to Barcelona, Venezuela BUT it doesn't work if we're trying to go from Montreal
        # end up with flights to London, United Kingdom. Also pushing country breaks addition of cohorts - all 'AND'
        # statements get changed to 'OR' so you end up with all flights to that country
        # e.g. WHERE origin_airport_iata_code = 'JFK' OR origin_country_iso_3166_code = 'US'
        def icao_cohort
          cohort_from_source 'ICAO TFS', [:origin_airport_city, :destination_airport_city, :aircraft_description, :airline_name]
        end

        def origin_airport
          characteristics[:origin_airport]
        end

        def destination_airport
          characteristics[:destination_airport]
        end

        def table
          return @table if @calculated == true
          @table_mutex.synchronize do
            return @table if @calculated == true
            @calculated = true

            subselect = if origin_airport.present? and destination_airport.present?
              if covered_by_bts?
                # NOTE: It's possible that the origin/destination pair won't appear in our database and we'll end up using a
                # cohort based just on origin. If that happens, even if the origin is not in the US we still don't want to use
                # origin airport city, because we know the flight was going to the US and ICAO segments never touch the US.
                # For example if there are direct flights from Rivendell to DC or London, but you enter a flight from Timbuktu to NYC.
                bts_cohort
              else
                icao_cohort
              end
            else
              bts_cohort.union icao_cohort
            end
            
            @subselect_sql = '(' + subselect.to_sql + ')'
            c = FlightSegment.connection
            @table_name = "flight_segment_cohort_#{::Kernel.rand(1e11)}"
            populated = false
            if c.adapter_name =~ /sqlite/i
              populated = true
              c.execute %{
                CREATE TEMPORARY TABLE #{table_name} AS
                SELECT * FROM #{subselect_sql}
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
                SELECT * FROM #{subselect_sql}
              }
            end
            if c.adapter_name =~ /mysql/i
              c.execute %{
                ANALYZE TABLE #{table_name}
              }
            end
            @table = Arel::SelectManager.new FlightSegment, Arel::Table.new(table_name)
          end
        end
      end
    end
  end
end
