Feature: Flight Emissions Calculations
  The flight model should generate correct emission calculations

  Scenario: Calculations from default
    Given a flight has nothing
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "42.5"

  Scenario Outline: Calculations from date
    Given a flight has "date" of "<date>"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "<emission>"
    Examples:
      | date       | emission |
      | 2009-06-25 | 0.0      |
      | 2010-06-25 | 42.5     |
      | 2011-06-25 | 0.0      |

  Scenario Outline: Calculations from date and timeframe
    Given a flight has "date" of "<date>"
    And it has "timeframe" of "<timeframe>"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "<emission>"
    Examples:
      | date       | timeframe             | emission |
      | 2009-06-25 | 2009-01-01/2009-01-31 | 0        |
      | 2009-06-25 | 2009-01-01/2009-12-31 | 42.5     |
      | 2009-06-25 | 2009-12-01/2009-12-31 | 0        |

  Scenario: Calculations from cohort based on origin
    Given a flight has "segments_per_trip" of "1"
    And it has "origin_airport.iata_code" of "AIA"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "106.8"

  Scenario: Calculations from cohort based on destination
    Given a flight has "segments_per_trip" of "1"
    And it has "destination_airport.iata_code" of "WEA"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "106.8"

  Scenario: Calculations from cohort based on aircraft
    Given a flight has "segments_per_trip" of "1"
    And it has "aircraft.icao_code" of "FM1"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "4.2"

  Scenario: Calculations from cohort based on airline
    Given a flight has "segments_per_trip" of "1"
    And it has "airline.iata_code" of "DA"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "6.3"

  Scenario: Calculations from segments per trip
    Given a flight has "segments_per_trip" of "2"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "45.8"

  Scenario: Calculations from seat class
    Given a flight has "seat_class.name" of "economy"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "38.3"

  Scenario: Calculations from trips
    Given a flight has "trips" of "2"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "43.8"

  Scenario: Calculations from load factor
    Given a flight has "load_factor" of "1"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "34.6"

  Scenario: Calculations from seats estimate
    Given a flight has "seats_estimate" of "100"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "52.5"

  Scenario: Calculations from aircraft class
    Given a flight has "aircraft_class.code" of "BX"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "114.6"

  Scenario: Calculations from country
    Given a flight has "country.iso_3166_code" of "UK"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "46.4"

  Scenario: Calculations from distance estimate
    Given a flight has "distance_estimate" of "185.2"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "6.6"

  Scenario: Calculations from distance class
    Given a flight has "distance_class.name" of "petite"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "6.6"

  Scenario: Calculations from aviation multiplier
    Given a flight has "aviation_multiplier" of "1"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "21.3"

  Scenario: Calculations from fuel type
    Given a flight has "fuel_type.name" of "Aviation Gasoline"
    When emissions are calculated
    Then the emission value should be within "0.1" kgs of "85.0"
