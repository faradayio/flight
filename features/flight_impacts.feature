Feature: Flight Impacts Calculations
  The flight model should generate correct impact calculations

  Background:
    Given a flight

  Scenario: Calculations from default
    Given a flight has nothing
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "91.96"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Calculations from date
    Given it has "date" of "<date>"
    And it is the year "2010"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "<impact>"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | date       | impact |
      | 2009-06-25 | 0.0    |
      | 2010-06-25 | 91.96  |
      | 2011-06-25 | 0.0    |

  Scenario Outline: Calculations from date and timeframe
    Given it has "date" of "<date>"
    And it has "timeframe" of "<timeframe>"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "<impact>"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | date       | timeframe             | impact |
      | 2009-06-25 | 2009-01-01/2009-01-31 | 0      |
      | 2009-06-25 | 2009-01-01/2009-12-31 | 91.96  |
      | 2009-06-25 | 2009-12-01/2009-12-31 | 0      |

  Scenario Outline: Calculations from cohorts that do not comply with standards
    Given it has "segments_per_trip" of "1"
    And it is the year "2011"
    And it has "origin_airport.iata_code" of "<origin>"
    And it has "destination_airport.iata_code" of "<dest>"
    And it has "airline.name" of "<airline>"
    And it has "aircraft.description" of "<aircraft>"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "<impact>"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | origin | dest | aircraft       | airline   | impact | comment |
      | JFK    |      |                |           | 170.33 | origin with just BTS segments |
      | FRA    |      |                |           |   7.00 | origin with just ICAO segments |
      | LHR    |      |                |           |  66.56 | origin with BTS and ICAO segments |
      |        | JFK  |                |           | 116.32 | dest with just BTS segments |
      |        | FRA  |                |           |  10.50 | dest with just ICAO segments |
      |        | LHR  |                |           |  69.67 | dest with BTS and ICAO segments |
      |        |      | boeing 737-400 |           |  61.91 | aircraft with simple description |
      |        |      | boeing 737-200 |           |  79.49 | aircraft with simple and complex descriptions |
      |        |      |                | Lufthansa |   7.47 | airline |

  Scenario Outline: Calculations from cohorts that comply with standards
    Given it has "segments_per_trip" of "1"
    And it is the year "2011"
    And it has "origin_airport.iata_code" of "<origin>"
    And it has "destination_airport.iata_code" of "<dest>"
    And it has "airline.name" of "<airline>"
    And it has "aircraft.description" of "<aircraft>"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "<impact>"
    And the calculation should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | origin | dest | aircraft       | airline   | impact | comment |
      | JFK    | LHR  |                |           | 170.33 | origin US destination foreign (BTS) |
      | LHR    | JFK  |                |           |  95.74 | origin foreign destination US (BTS) |
      | FRA    | LHR  |                |           |   7.00 | origin/destination foreign (ICAO) |
      | JFK    | ATL  | boeing 737-400 |           |  15.61 | origin/destination + airline but destination not in flight segments |
      | JFK    | FRA  |                |           | 187.36 | origin + dest no match; origin or dest in US, origin has BTS segments only |
      | FRA    | FRA  |                |           |   0.00 | origin + dest no match; origin + dest not in US, origin has ICAO segments only |

  Scenario: Calculations from segments per trip
    Given it has "segments_per_trip" of "2"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "98.77"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Calculations from seat class
    Given it has "seat_class_name" of "economy"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "82.76"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Calculations from seat class and distance estimate
    Given it has "seat_class_name" of "economy"
    And it has "distance_estimate" of "5000"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "219.24"
    And the calculation should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Calculations from trips
    Given it has "trips" of "2"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "108.19"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Calculations from load factor
    Given it has "load_factor" of "1"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "77.29"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Calculations from seats estimate
    Given it has "seats_estimate" of "100"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "236.47"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Calculations from distance estimate
    Given it has "distance_estimate" of "185.2"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "11.60"
    And the calculation should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Calculations from distance class
    Given it has "distance_class.name" of "short haul"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "68.90"
    And the calculation should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Calculations from fuel
    Given it has "fuel.name" of "Aviation Gasoline"
    When impacts are calculated
    Then the amount of "carbon" should be within "0.01" of "88.93"
    And the calculation should not comply with standards "ghg_protocol_scope_3, iso, tcr"
