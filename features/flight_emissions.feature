Feature: Flight Emissions Calculations
  The flight model should generate correct emission calculations

  Scenario: Calculations from default
    Given a flight has nothing
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "94.66"
  
  Scenario Outline: Calculations from date
    Given a flight has "date" of "<date>"
    And it is the year "2010"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "<emission>"
    Examples:
      | date       | emission |
      | 2009-06-25 | 0.0      |
      | 2010-06-25 | 94.66    |
      | 2011-06-25 | 0.0      |
  
  Scenario Outline: Calculations from date and timeframe
    Given a flight has "date" of "<date>"
    And it has "timeframe" of "<timeframe>"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "<emission>"
    Examples:
      | date       | timeframe             | emission |
      | 2009-06-25 | 2009-01-01/2009-01-31 | 0        |
      | 2009-06-25 | 2009-01-01/2009-12-31 | 94.66    |
      | 2009-06-25 | 2009-12-01/2009-12-31 | 0        |
  
  Scenario Outline: Calculations from various cohorts
    Given a flight has "segments_per_trip" of "1"
    And it is the year "2011"
    And it has "origin_airport.iata_code" of "<origin>"
    And it has "destination_airport.iata_code" of "<dest>"
    And it has "airline.name" of "<airline>"
    And it has "aircraft.description" of "<aircraft>"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "<emission>"
    Examples:
      | origin | dest | aircraft       | airline   | emission |
      | JFK    |      |                |           | 178.41   |
      | FRA    |      |                |           | 7.00     |
      | LHR    |      |                |           | 68.05    |
      |        | JFK  |                |           | 119.73   |
      |        | FRA  |                |           | 10.50    |
      |        | LHR  |                |           | 71.58    |
      |        |      | boeing 737-400 |           | 75.00    |
      |        |      | boeing 737-200 |           | 89.07    |
      |        |      |                | Lufthansa | 7.47     |
      | JFK    | LHR  |                |           | 178.41   |
      | LHR    | JFK  |                |           | 98.55    |
      | FRA    | LHR  |                |           | 7.00     |
      | JFK    | ATL  | boeing 737-400 |           | 10.88    |
      | JFK    | FRA  |                |           | 196.25   |
      | FRA    | FRA  |                |           | 0.0      |
      # origin with just BTS segments
      # origin with just ICAO segments
      # origin with BTS and ICAO segments
      # dest with just BTS segments
      # dest with just ICAO segments
      # dest with BTS and ICAO segments
      # aircraft with simple description
      # aircraft with simple and complex descriptions
      # airline
      # origin US destination foreign (BTS)
      # origin foreign destination US (BTS)
      # origin/destination foreign (ICAO)
      # origin/destination + airline but destination not in flight segments
      # origin + dest don't match; origin or dest in US, origin has BTS segments only
      # origin + dest don't match; origin + dest not in US, origin has ICAO segments only

  Scenario: Calculations from segments per trip
    Given a flight has "segments_per_trip" of "2"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "101.66"

  Scenario: Calculations from seat class
    Given a flight has "seat_class_name" of "economy"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "91.87"

  Scenario: Calculations from seat class and distance estimate
    Given a flight has "seat_class_name" of "economy"
    And it has "distance_estimate" of "2000"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "94.06"

  Scenario: Calculations from trips
    Given a flight has "trips" of "2"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "111.36"

  Scenario: Calculations from load factor
    Given a flight has "load_factor" of "1"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "79.56"

  Scenario: Calculations from seats estimate
    Given a flight has "seats_estimate" of "100"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "243.41"

  Scenario: Calculations from distance estimate
    Given a flight has "distance_estimate" of "185.2"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "11.94"

  Scenario: Calculations from distance class
    Given a flight has "distance_class.name" of "short haul"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "11.94"

  Scenario: Calculations from fuel
    Given a flight has "fuel.name" of "Aviation Gasoline"
    When emissions are calculated
    Then the emission value should be within "0.01" kgs of "91.54"
