module BrighterPlanet
  module Flight
    module ImpactModel
      class FuelUseEquation
        class Derived < FuelUseEquation
          attr_reader :flight_segment_cohort

          def initialize(flight_segment_cohort)
            @calculate_mutex = Mutex.new
            @flight_segment_cohort = flight_segment_cohort
          end
          
          def m3
            calculate!
            @m3
          end

          def m2
            calculate!
            @m2
          end

          def m1
            calculate!
            @m1
          end

          def b
            calculate!
            @b
          end
        
          private

          def connection
            Aircraft.connection
          end

          def execute(sql)
            connection.execute sql
          end

          def sqlite?
            connection.adapter_name =~ /sqlite/i
          end

          def mysql?
            connection.adapter_name =~ /mysql/i
          end
        
          def calculate!
            return if @calculated == true
            @calculate_mutex.synchronize do
              return if @calculated == true
              @calculated = true

              table_name = "flight_fuel_use_coefficients_#{Kernel.rand(1e11)}"

              execute %{
                CREATE TEMPORARY TABLE #{table_name} (
                  aircraft_description VARCHAR(255),
                  m3 FLOAT,
                  m2 FLOAT,
                  m1 FLOAT,
                  b FLOAT,
                  passengers INT
                )
              }

              # make this run faster if you're on mysql
              if mysql?
                execute %{ ALTER TABLE #{table_name} ENGINE=MEMORY }
              end

              # make sure that [lazy-loading] flight segment cohort tmp table has been created, because it's about to be used
              if flight_segment_cohort.is_a? FlightSegmentCohort
                flight_segment_cohort.generate_tmp_table!
                aircraft_descriptions_sql = %{ SELECT DISTINCT #{flight_segment_cohort.table_name}.aircraft_description FROM #{flight_segment_cohort.table_name} }
                passengers_sql = %{ ( SELECT SUM(passengers) FROM #{flight_segment_cohort.table_name} WHERE #{flight_segment_cohort.table_name}.aircraft_description = #{table_name}.aircraft_description ) }
              else
                flight_segment = flight_segment_cohort.first
                aircraft_descriptions_sql = connection.quote flight_segment.aircraft_description
                passengers_sql = connection.quote flight_segment.passengers
              end

              # - For each unique aircraft description:
              # - 1. look up all the aircraft it refers to
              # - 2. average those aircraft's fuel use coefficients
              # - 3. store the resulting values in the temporary table along with the unique aircraft_description
              execute %{
                INSERT INTO #{table_name} (aircraft_description, m3, m2, m1, b)
                  SELECT fz.b, AVG(ac.m3), AVG(ac.m2), AVG(ac.m1), AVG(ac.b)
                  FROM #{FuzzyMatch::CachedResult.quoted_table_name} AS fz
                    INNER JOIN #{Aircraft.quoted_table_name} AS ac
                    ON fz.a = ac.description AND fz.a_class = 'Aircraft' AND fz.b_class = 'FlightSegment'
                  WHERE fz.b IN (#{aircraft_descriptions_sql})
                  GROUP BY fz.b
              }

              # - For each unique aircraft description:
              # - 1. look up all the flight segments that match the aircraft description
              # - 2. sum passengers across those flight segments
              # - 3. store the resulting value in the temporary table
              execute %{
                UPDATE #{table_name}
                SET passengers = #{passengers_sql}
              }

              # - Calculate the average of the coefficients in the temporary table, weighted by passengers
              row = connection.select_one %{
                SELECT
                  SUM(1.0 * m3 * passengers)/SUM(passengers) AS avg_m3,
                  SUM(1.0 * m2 * passengers)/SUM(passengers) AS avg_m2,
                  SUM(1.0 * m1 * passengers)/SUM(passengers) AS avg_m1,
                  SUM(1.0 * b * passengers)/SUM(passengers)  AS avg_b
                FROM #{table_name}
                WHERE
                  m3 IS NOT NULL
                  AND m2 IS NOT NULL
                  AND m1 IS NOT NULL
                  AND b IS NOT NULL
                  AND passengers > 0
              }

              @m3, @m2, @m1, @b = row['avg_m3'], row['avg_m2'], row['avg_m1'], row['avg_b']

              execute %{ DROP TABLE #{table_name} }
            end
          end
        end
      end
    end
  end
end
