Feature: Flight Emissions Calculations
  The flight model should generate correct emission calculations

  Scenario: Calculations from default
    Given a flight has nothing
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "37.32"

  Scenario Outline: Calculations from date
    Given a flight has "date" of "<date>"
    And it is the year "2010"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "<emission>"
    Examples:
      | date       | emission |
      | 2009-06-25 | 0.0      |
      | 2010-06-25 | 37.32    |
      | 2011-06-25 | 0.0      |

  Scenario Outline: Calculations from date and timeframe
    Given a flight has "date" of "<date>"
    And it has "timeframe" of "<timeframe>"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "<emission>"
    Examples:
      | date       | timeframe             | emission |
      | 2009-06-25 | 2009-01-01/2009-01-31 | 0        |
      | 2009-06-25 | 2009-01-01/2009-12-31 | 37.32    |
      | 2009-06-25 | 2009-12-01/2009-12-31 | 0        |

  Scenario: Calculations from cohort based on origin
    Given a flight has "segments_per_trip" of "1"
    And it has "origin_airport.iata_code" of "AIA"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "93.54"

  Scenario: Calculations from cohort based on destination
    Given a flight has "segments_per_trip" of "1"
    And it has "destination_airport.iata_code" of "WEA"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "93.54"

  Scenario: Calculations from cohort based on aircraft
    Given a flight has "segments_per_trip" of "1"
    And it has "aircraft.icao_code" of "FM1"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "3.7"

  Scenario: Calculations from cohort based on airline
    Given a flight has "segments_per_trip" of "1"
    And it has "airline.iata_code" of "DA"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "5.53"

  Scenario: Calculations from segments per trip
    Given a flight has "segments_per_trip" of "2"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "40.08"

  Scenario: Calculations from seat class
    Given a flight has "seat_class_name" of "economy"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "36.22"

  Scenario: Calculations from seat class and distance estimate
    Given a flight has "seat_class_name" of "economy"
    And it has "distance_estimate" of "1666.8"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "50.94"

  Scenario: Calculations from trips
    Given a flight has "trips" of "2"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "43.9"

  Scenario: Calculations from load factor
    Given a flight has "load_factor" of "1"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "30.34"

  Scenario: Calculations from seats estimate
    Given a flight has "seats_estimate" of "100"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "46.07"

  Scenario: Calculations from aircraft class
    Given a flight has "aircraft_class.code" of "BX"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "100.59"

  Scenario: Calculations from country
    Given a flight has "country.iso_3166_code" of "UK"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "40.71"

  Scenario: Calculations from distance estimate
    Given a flight has "distance_estimate" of "185.2"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "5.83"

  Scenario: Calculations from distance class
    Given a flight has "distance_class.name" of "petite"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "5.83"

  Scenario: Calculations from fuel type
    Given a flight has "fuel_type.name" of "Aviation Gasoline"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "74.64"
