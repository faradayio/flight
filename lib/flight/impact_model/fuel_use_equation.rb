module BrighterPlanet
  module Flight
    module ImpactModel
      class FuelUseEquation < ::Struct.new(:m3, :m2, :m1, :b)
        class << self
          def new_if_valid(*args)
            if (equation = new(*args)).valid?
              equation
            end
          end
          
          def from(cohort_conditions)
            # - Create a temporary table to hold the values we need
            c = ::ActiveRecord::Base.connection
            c.execute %{
              DROP TABLE IF EXISTS tmp_fuel_use_coefficients
            }
            
            create_table_sql = %{
              CREATE TEMPORARY TABLE tmp_fuel_use_coefficients (
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

            # - Look up the unique aircraft descriptions in `cohort`
            aircraft_descriptions = c.select_values %{
              SELECT DISTINCT aircraft_description
              FROM #{::FlightSegment.quoted_table_name}
              WHERE (#{cohort_conditions})
            }

            # - For each unique aircraft description:
            # - 1. look up all the aircraft it refers to
            # - 2. average those aircraft's fuel use coefficients
            # - 3. store the resulting values in the temporary table along with the unique aircraft_description
            c.execute %{
              INSERT INTO tmp_fuel_use_coefficients (description, m3, m2, m1, b)
                SELECT t1.b, AVG(t2.m3), AVG(t2.m2), AVG(t2.m1), AVG(t2.b)
                FROM #{::LooseTightDictionary::CachedResult.quoted_table_name} AS t1
                  INNER JOIN #{::Aircraft.quoted_table_name} AS t2
                  ON t1.a = t2.description
                WHERE t1.b IN ('#{aircraft_descriptions.join("', '")}')
                GROUP BY t1.b
            }

            # - For each unique aircraft description:
            # - 1. look up all the flight segments in `cohort` that match the aircraft description
            # - 2. sum passengers across those flight segments
            # - 3. store the resulting value in the temporary table
            c.execute %{
              UPDATE tmp_fuel_use_coefficients
              SET passengers = (
                SELECT SUM(passengers)
                FROM #{::FlightSegment.quoted_table_name}
                WHERE (#{cohort_conditions})
                AND #{::FlightSegment.quoted_table_name}.aircraft_description = tmp_fuel_use_coefficients.description
              )
            }

            # - Calculate the average of the coefficients in the temporary table, weighted by passengers
            row = c.select_one %{
              SELECT
                SUM(1.0 * m3 * passengers)/SUM(passengers) AS a_m3,
                SUM(1.0 * m2 * passengers)/SUM(passengers) AS a_m2,
                SUM(1.0 * m1 * passengers)/SUM(passengers) AS a_m1,
                SUM(1.0 * b * passengers)/SUM(passengers)  AS a_b
              FROM tmp_fuel_use_coefficients
              WHERE
                m3 IS NOT NULL
                AND m2 IS NOT NULL
                AND m1 IS NOT NULL
                AND b IS NOT NULL
                AND passengers > 0
            }

            new_if_valid row['a_m3'], row['a_m2'], row['a_m1'], row['a_b']
            
            c.execute %{
              DROP TABLE tmp_fuel_use_coefficients
            }
          end
        end
        
        def values
          [m3, m2, m1, b]
        end
        
        def valid?
          values.all?(&:present?) and values.any?(&:nonzero?)
        end
      end
    end
  end
end
