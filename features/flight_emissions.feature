Feature: Flight Emissions Calculations
  The flight model should generate correct emission calculations

  Scenario: Calculations from default
    Given a flight has nothing
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "132.31"

  Scenario Outline: Calculations from date
    Given a flight has "date" of "<date>"
    And it is the year "2010"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "<emission>"
    Examples:
      | date       | emission |
      | 2009-06-25 | 0.0      |
      | 2010-06-25 | 132.31   |
      | 2011-06-25 | 0.0      |

  Scenario Outline: Calculations from date and timeframe
    Given a flight has "date" of "<date>"
    And it has "timeframe" of "<timeframe>"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "<emission>"
    Examples:
      | date       | timeframe             | emission |
      | 2009-06-25 | 2009-01-01/2009-01-31 | 0        |
      | 2009-06-25 | 2009-01-01/2009-12-31 | 132.31   |
      | 2009-06-25 | 2009-12-01/2009-12-31 | 0        |

  Scenario: Calculations from cohort based on origin
    Given a flight has "segments_per_trip" of "1"
    And it has "origin_airport.iata_code" of "AIA"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "331.65"

  Scenario: Calculations from cohort based on destination
    Given a flight has "segments_per_trip" of "1"
    And it has "destination_airport.iata_code" of "WEA"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "331.65"

  Scenario: Calculations from cohort based on aircraft
    Given a flight has "segments_per_trip" of "1"
    And it has "aircraft.icao_code" of "FM1"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "13.12"

  Scenario: Calculations from cohort based on airline
    Given a flight has "segments_per_trip" of "1"
    And it has "airline.iata_code" of "DA"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "19.59"

  Scenario: Calculations from segments per trip
    Given a flight has "segments_per_trip" of "2"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "142.10"

  Scenario: Calculations from seat class
    Given a flight has "seat_class_name" of "economy"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "128.42"

  Scenario: Calculations from seat class and distance estimate
    Given a flight has "seat_class_name" of "economy"
    And it has "distance_estimate" of "1666.8"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "180.59"

  Scenario: Calculations from trips
    Given a flight has "trips" of "2"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "155.66"

  Scenario: Calculations from load factor
    Given a flight has "load_factor" of "1"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "107.57"

  Scenario: Calculations from seats estimate
    Given a flight has "seats_estimate" of "100"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "163.34"

  Scenario: Calculations from aircraft class
    Given a flight has "aircraft_class.code" of "BX"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "356.63"

  Scenario: Calculations from country
    Given a flight has "country.iso_3166_code" of "UK"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "132.31"

  Scenario: Calculations from distance estimate
    Given a flight has "distance_estimate" of "185.2"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "20.67"

  Scenario: Calculations from distance class
    Given a flight has "distance_class.name" of "petite"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "20.67"

  Scenario: Calculations from fuel
    Given a flight has "fuel.name" of "Aviation Gasoline"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "127.95"
