module BrighterPlanet
  module Flight
    module ImpactModel
      class FuelUseEquation
        class << self
          def from_coefficients(m3, m2, m1, b)
            equation = new
            equation.m3 = m3
            equation.m2 = m2
            equation.m1 = m1
            equation.b = b
            if equation.valid?
              equation
            else
              nil
            end
          end

          def from_flight_segments(relation)
            equation = new
            equation.where_sql = relation.where_sql
            if equation.valid?
              equation
            else
              nil
            end
          end
        end

        attr_writer :m3, :m2, :m1, :b
        attr_accessor :where_sql

        def valid?
          coefficients.all?(&:present?) and coefficients.any?(&:nonzero?)
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
        
        def coefficients
          [ m3, m2, m1, b ]
        end

        # In case you want to `cache_method :m3` this
        def method_cache_hash
          [ @m3, @m2, @m1, @b, @where_sql ].hash
        end
        
        private

        def calculate!
          return if @calculated == true
          @calculated = true
          return unless where_sql

          # - Create a temporary table to hold the values we need
          c = ::ActiveRecord::Base.connection

          table_name = "flight_fuel_use_coefficients_#{::Kernel.rand(1e11)}"

          create_table_sql = %{
            CREATE TEMPORARY TABLE #{table_name} (
              description VARCHAR(255),
              m3 FLOAT,
              m2 FLOAT,
              m1 FLOAT,
              b FLOAT,
              passengers INT
            )
          }

          # make this run faster if you're on mysql
          create_table_sql << 'ENGINE=MEMORY' if c.adapter_name =~ /mysql/i

          c.execute create_table_sql

          # - Look up the unique aircraft descriptions in `where_sql`
          aircraft_descriptions = c.select_values %{
            SELECT DISTINCT aircraft_description
            FROM #{::FlightSegment.quoted_table_name}
            #{where_sql}
          }

          # - For each unique aircraft description:
          # - 1. look up all the aircraft it refers to
          # - 2. average those aircraft's fuel use coefficients
          # - 3. store the resulting values in the temporary table along with the unique aircraft_description
          c.execute %{
            INSERT INTO #{table_name} (description, m3, m2, m1, b)
              SELECT t1.b, AVG(t2.m3), AVG(t2.m2), AVG(t2.m1), AVG(t2.b)
              FROM #{::FuzzyMatch::CachedResult.quoted_table_name} AS t1
                INNER JOIN #{::Aircraft.quoted_table_name} AS t2
                ON t1.a = t2.description
              WHERE t1.b IN ('#{aircraft_descriptions.join("', '")}')
              GROUP BY t1.b
          }

          # - For each unique aircraft description:
          # - 1. look up all the flight segments in `where_sql` that match the aircraft description
          # - 2. sum passengers across those flight segments
          # - 3. store the resulting value in the temporary table
          c.execute %{
            UPDATE #{table_name}
            SET passengers = (
              SELECT SUM(passengers)
              FROM #{::FlightSegment.quoted_table_name}
              #{where_sql} AND #{::FlightSegment.quoted_table_name}.aircraft_description = #{table_name}.description
            )
          }

          # - Calculate the average of the coefficients in the temporary table, weighted by passengers
          row = c.select_one %{
            SELECT
              SUM(1.0 * m3 * passengers)/SUM(passengers) AS a_m3,
              SUM(1.0 * m2 * passengers)/SUM(passengers) AS a_m2,
              SUM(1.0 * m1 * passengers)/SUM(passengers) AS a_m1,
              SUM(1.0 * b * passengers)/SUM(passengers)  AS a_b
            FROM #{table_name}
            WHERE
              m3 IS NOT NULL
              AND m2 IS NOT NULL
              AND m1 IS NOT NULL
              AND b IS NOT NULL
              AND passengers > 0
          }

          @m3, @m2, @m1, @b = row['a_m3'], row['a_m2'], row['a_m1'], row['a_b']

          c.execute %{
            DROP TABLE #{table_name}
          }
        end
      end
    end
  end
end
