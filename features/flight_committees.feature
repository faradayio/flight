Feature: Flight Committee Calculations
  The flight model should generate correct committee calculations

  Scenario: Date committee from timeframe
    Given a flight emitter
    And a characteristic "timeframe" of "2010-07-15/2010-07-20"
    When the "date" committee is calculated
    Then the conclusion of the committee should be "2010-07-15"

  Scenario: Segments per trip committee from default
    Given a flight emitter
    When the "segments_per_trip" committee is calculated
    Then the conclusion of the committee should be "1.67"

  Scenario: Cohort committee for a direct flight from origin
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "AIA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "3"

  Scenario: Cohort committee for a direct flight from destination
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "destination_airport.iata_code" of "WEA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "3"

  Scenario: Cohort committee for a direct flight from aircraft
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "aircraft.bp_code" of "BP-FM1"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "1"

  Scenario: Cohort committee for a direct flight from airline
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "airline.iata_code" of "DA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "2"

  Scenario: Cohort committee for an indirect flight with usable characteristics
    Given a flight emitter
    And a characteristic "segments_per_trip" of "2"
    And a characteristic "origin_airport.iata_code" of "AIA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Cohort committee for a direct flight with origin that exists but is not in t100
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "XXX"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Cohort committee for a direct flight with destination that exists but is not in t100
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "destination_airport.iata_code" of "ADA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Cohort committee for a direct flight with aircraft that exists but is not in t100
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "aircraft.bp_code" of "BP-XX2"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Cohort committee for a direct flight with airline that exists but is not in t100
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "airline.iata_code" of "XX"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Cohort committee for a direct flight with origin and destination that do not match
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "ADA"
    And a characteristic "destination_airport.iata_code" of "WEA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "2"

  Scenario: Cohort committee for a direct flight with origin that exists but is not in t100 and destination in t100
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "XXX"
    And a characteristic "destination_airport.iata_code" of "AIA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Cohort committee for a direct flight with origin in t100, destination that exists but is not in t100, and airline that matches origin
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "AIA"
    And a characteristic "destination_airport.iata_code" of "XXX"
    And a characteristic "airline.iata_code" of "IA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "3"

  Scenario: Aircraft class committee from aircraft
    Given a flight emitter
    And a characteristic "aircraft.bp_code" of "BP-FM1"
    When the "aircraft_class" committee is calculated
    Then the conclusion of the committee should have "code" of "EX"

  Scenario: Country committee from origin and destination
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "ADA"
    And a characteristic "destination_airport.iata_code" of "AIA"
    When the "country" committee is calculated
    Then the conclusion of the committee should have "iso_3166_code" of "US"

  Scenario: Country committee from origin only
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "ADA"
    When the "country" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Country committee for international flight
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "AIA"
    And a characteristic "destination_airport.iata_code" of "WEA"
    When the "country" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Seat class multiplier committee from seat class
    Given a flight emitter
    And a characteristic "seat_class.name" of "economy"
    When the "seat_class_multiplier" committee is calculated
    Then the committee should have used quorum "from seat class"
    And the conclusion of the committee should be "0.9"

  Scenario: Seat class multiplier committee from default
    Given a flight emitter
    When the "seat_class_multiplier" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1.0"

  Scenario: Trips committee from default
    Given a flight emitter
    When the "trips" committee is calculated
    Then the conclusion of the committee should be "1.941"

  Scenario: Freight share committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "AIA"
    When the "cohort" committee is calculated
    And the "freight_share" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "0.06205"

  Scenario: Freight share committee from default
    Given a flight emitter
    When the "freight_share" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "0.04313"

  Scenario: Load factor committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "AIA"
    When the "cohort" committee is calculated
    And the "load_factor" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "0.81197"

  Scenario: Load factor committee from default
    Given a flight emitter
    When the "load_factor" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "0.81385"

  Scenario Outline: Seats committee from aircraft with seats
    Given a flight emitter
    And a characteristic "aircraft.bp_code" of "<code>"
    When the "seats" committee is calculated
    Then the committee should have used quorum "from aircraft"
    And the conclusion of the committee should be "<seats>"
    Examples:
      | code    | seats  |
      | BP-FM1  | 125.0  |
      | BP-BA1  | 120.0  |
      | BP-XX1  | 130.0  |

  Scenario Outline: Seats committee from aircraft missing seats
    Given a flight emitter
    And a characteristic "aircraft.bp_code" of "<code>"
    When the "seats" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "123.0"
    Examples:
      | code   |
      | BP-XX2 |
      | BP-XX3 |
      | BP-XX4 |

  Scenario: Seats committee from seats estimate
    Given a flight emitter
    And a characteristic "seats_estimate" of "100.25"
    When the "seats" committee is calculated
    Then the committee should have used quorum "from seats estimate"
    And the conclusion of the committee should be "100"

  Scenario: Seats committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "ADA"
    When the "cohort" committee is calculated
    And the "seats" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "122.5"

  Scenario: Seats committee from aircraft class
    Given a flight emitter
    And a characteristic "aircraft_class.code" of "EX"
    When the "seats" committee is calculated
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should be "121.25"

  Scenario: Seats committee from default
    Given a flight emitter
    When the "seats" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "123.0"

  Scenario: Passengers committee from seats and load factor
    Given a flight emitter
    And a characteristic "seats" of "105"
    And a characteristic "load_factor" of "0.9"
    When the "passengers" committee is calculated
    Then the conclusion of the committee should be "95"

  Scenario: Fuel type committee from default
    Given a flight emitter
    When the "fuel_type" committee is calculated
    Then the conclusion of the committee should have "name" of "Jet Fuel"

  Scenario Outline: Fuel use coefficients committee from aircraft with fuel use coefficients
    Given a flight emitter
    And a characteristic "aircraft.bp_code" of "<code>"
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from aircraft"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "<b>"
    Examples:
      | code   | m3 | m2 | m1 | b |
      | BP-FM1 | 0  | 0  | 1  | 0 |
      | BP-BA1 | 0  | 0  | 2  | 0 |
      | BP-XX2 | 0  | 0  | 4  | 0 |

  Scenario Outline: Fuel use coefficients committee from aircraft missing fuel use coefficients
    Given a flight emitter
    And a characteristic "aircraft.bp_code" of "<code>"
    When the "aircraft_class" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should have a record with "m3" equal to "0"
    And the conclusion of the committee should have a record with "m2" equal to "0"
    And the conclusion of the committee should have a record with "m1" equal to "4"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "0"
    Examples:
      | code   |
      | BP-XX1 |
      | BP-XX3 |
      | BP-XX4 |

  Scenario: Fuel use coefficients committee from aircraft class
    Given a flight emitter
    And a characteristic "aircraft_class.code" of "EX"
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should have a record with "m3" equal to "0"
    And the conclusion of the committee should have a record with "m2" equal to "0"
    And the conclusion of the committee should have a record with "m1" equal to "1.75"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "0"

  Scenario: Fuel use coefficients committee from cohort where all aircraft have fuel use equation
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "ADA"
    When the "cohort" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should have a record with "m3" equal to "0"
    And the conclusion of the committee should have a record with "m2" equal to "0"
    And the conclusion of the committee should have a record with "m1" equal to "1.5"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "0"

  Scenario: Fuel use coefficients committee from cohort where some aircraft are missing fuel use equation
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "AIA"
    When the "cohort" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should have a record with "m3" equal to "0"
    And the conclusion of the committee should have a record with "m2" equal to "0"
    And the conclusion of the committee should have a record with "m1" equal to "2.66667"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "0"

  Scenario: Fuel use coefficients committee from cohort where all aircraft are missing fuel use equation
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "AIA"
    And a characteristic "airline.iata_code" of "EA"
    When the "cohort" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should have a record with "m3" equal to "0"
    And the conclusion of the committee should have a record with "m2" equal to "0"
    And the conclusion of the committee should have a record with "m1" equal to "4"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "0"

  Scenario: Fuel use coefficients committee from default
    Given a flight emitter
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should have a record with "m3" equal to "0"
    And the conclusion of the committee should have a record with "m2" equal to "0"
    And the conclusion of the committee should have a record with "m1" equal to "1.4"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "0"

  Scenario: Dogleg factor committee from segments per trip
    Given a flight emitter
    And a characteristic "segments_per_trip" of "2"
    When the "dogleg_factor" committee is calculated
    Then the conclusion of the committee should be "1.25"

  Scenario: Route inefficiency factor committee from country
    Given a flight emitter
    And a characteristic "country.iso_3166_code" of "US"
    When the "route_inefficiency_factor" committee is calculated
    Then the committee should have used quorum "from country"
    And the conclusion of the committee should be "1.1"

  Scenario: Route inefficiency factor committee from default
    Given a flight emitter
    When the "route_inefficiency_factor" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1.1"

  Scenario: Route inefficiency factor after country committee has returned nil
    Given a flight emitter
    When the "country" committee is calculated
    And the "route_inefficiency_factor" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1.1"

  Scenario Outline: Distance committee from airports
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<destination>"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from airports"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | origin | destination | distance |
      | ADA    | AIA         |  100.0   |
      | AIA    | WEA         | 1000.0   |

  Scenario: Distance committee from distance estimate
    Given a flight emitter
    And a characteristic "distance_estimate" of "185.2"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from distance estimate"
    And the conclusion of the committee should be "100.0"

  Scenario: Distance committee from distance class
    Given a flight emitter
    And a characteristic "distance_class.name" of "petite"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from distance class"
    And the conclusion of the committee should be "100.0"

  Scenario: Distance committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "ADA"
    When the "cohort" committee is calculated
    And the "distance" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "100.0"

  Scenario: Distance committee from default
    Given a flight emitter
    When the "distance" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "640.0"

  Scenario: Adjusted distance committee from distance, route inefficiency factor, and dogleg factor
    Given a flight emitter
    And a characteristic "distance" of "100"
    And a characteristic "route_inefficiency_factor" of "1.1"
    And a characteristic "dogleg_factor" of "1.25"
    When the "adjusted_distance" committee is calculated
    Then the conclusion of the committee should be "137.5"

  Scenario: Adjusted distance per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance" of "100"
    And a characteristic "segments_per_trip" of "2"
    When the "adjusted_distance_per_segment" committee is calculated
    Then the conclusion of the committee should be "50"

  Scenario: Fuel per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "100"
    And a characteristic "aircraft.bp_code" of "BP-BA1"
    When the "fuel_use_coefficients" committee is calculated
    And the "fuel_per_segment" committee is calculated
    Then the conclusion of the committee should be "200"

  Scenario: Fuel committee
    Given a flight emitter
    And a characteristic "fuel_per_segment" of "100"
    And a characteristic "segments_per_trip" of "2"
    And a characteristic "trips" of "2"
    When the "fuel" committee is calculated
    Then the conclusion of the committee should be "400"

  Scenario: Aviation multiplier committee from default
    Given a flight emitter
    When the "aviation_multiplier" committee is calculated
    Then the conclusion of the committee should be "2"

  Scenario: Emission factor committee from default fuel type
    Given a flight emitter
    When the "fuel_type" committee is calculated
    And the "emission_factor" committee is calculated
    Then the conclusion of the committee should be "1.0"
