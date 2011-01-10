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

  Scenario Outline: Cohort committee from various characteristics
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin_iata>"
    And a characteristic "destination_airport.iata_code" of "<destination_iata>"
    And a characteristic "aircraft.bp_code" of "<aircraft_code>"
    And a characteristic "airline.iata_code" of "<airline_iata>"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "<records>"
    Examples:
      | origin_iata | destination_iata | aircraft_code | airline_iata | records |
      | AIA         |                  |               |              | 3       |
      |             | WEA              |               |              | 3       |
      |             |                  | BP-FM1        |              | 1       |
      |             |                  |               | DA           | 2       |
      |             | WEA              | BP-BA1        |              | 2       |
      | AIA         | XXX              |               | IA           | 3       |
      | ADA         | WEA              |               |              | 2       |
      # origin ok
      # dest ok
      # aircraft ok
      # airline ok
      # two characteristics
      # origin + airline ok but dest not in t100
      # origin + dest don't match

  Scenario Outline: Cohort committe from various unusable characteristics
    Given a flight emitter
    And a characteristic "segments_per_trip" of "<segments>"
    And a characteristic "origin_airport.iata_code" of "<origin_iata>"
    And a characteristic "destination_airport.iata_code" of "<destination_iata>"
    And a characteristic "aircraft.bp_code" of "<aircraft_code>"
    And a characteristic "airline.iata_code" of "<airline_iata>"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil
    Examples:
      | segments | origin_iata | destination_iata | aircraft_code | airline_iata |
      | 2        | AIA         |                  |               |              |
      | 1        | XXX         |                  |               |              |
      | 1        |             | ADA              |               |              |
      | 1        |             |                  | BP-XX2        |              |
      | 1        |             |                  |               | XX           |
      | 1        | XXX         | AIA              |               | XX           |
      # indirect flight
      # origin exists but not in t100
      # dest exists but not in t100
      # aircraft exists but not in t100
      # airline exists but not in t100
      # origin not in t100, dest in t100

  Scenario: Cohort committee from segments with no passengers should be nil
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "AZP"
    And a characteristic "destination_airport.iata_code" of "BZP"
    And a characteristic "aircraft.bp_code" of "6"
    And a characteristic "airline.iata_code" of "ZA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil

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

  Scenario Outline: Freight share committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin_iata>"
    And a characteristic "destination_airport.iata_code" of "<destination_iata>"
    And a characteristic "aircraft.bp_code" of "<aircraft_code>"
    And a characteristic "airline.iata_code" of "<airline_iata>"
    When the "cohort" committee is calculated
    And the "freight_share" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<freight_share>"
    Examples:
      | origin_iata | destination_iata | aircraft_code | airline_iata | freight_share |
      | AIA         |                  |               |              | 0.06205       |
      |             | WEA              |               |              | 0.06205       |
      |             |                  | BP-FM1        |              | 0.00990       |
      |             |                  |               | DA           | 0.01475       |

  Scenario: Freight share committee from default
    Given a flight emitter
    When the "freight_share" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "0.04313"

  Scenario Outline: Load factor committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin_iata>"
    And a characteristic "destination_airport.iata_code" of "<destination_iata>"
    And a characteristic "aircraft.bp_code" of "<aircraft_code>"
    And a characteristic "airline.iata_code" of "<airline_iata>"
    When the "cohort" committee is calculated
    And the "load_factor" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<load_factor>"
    Examples:
      | origin_iata | destination_iata | aircraft_code | airline_iata | load_factor |
      | AIA         |                  |               |              | 0.81197     |
      |             | WEA              |               |              | 0.81197     |
      |             |                  | BP-FM1        |              | 0.8         |
      |             |                  |               | DA           | 0.81667     |

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
      | BP-XX1s | 130.0  |

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

  Scenario Outline: Seats committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin_iata>"
    And a characteristic "destination_airport.iata_code" of "<destination_iata>"
    And a characteristic "airline.iata_code" of "<airline_iata>"
    When the "cohort" committee is calculated
    And the "seats" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<seats>"
    Examples:
      | origin_iata | destination_iata | airline_iata | seats     |
      | AIA         |                  |              | 123.33333 |
      |             | WEA              |              | 123.33333 |
      |             |                  | DA           | 122.5     |

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

  Scenario Outline: Passengers committee from seats and load factor
    Given a flight emitter
    And a characteristic "seats" of "<seats>"
    And a characteristic "load_factor" of "<load_factor>"
    When the "passengers" committee is calculated
    Then the conclusion of the committee should be "<passengers>"
    Examples:
      | seats | load_factor | passengers |
      | 105   | 0.9         | 95.0       |
      | 123   | 0.81385     | 100.0      |

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
      | code   | m3  | m2  | m1  | b   |
      | BP-FM1 | 0.0 | 0.0 | 1.0 | 0.0 |
      | BP-BA1 | 0.0 | 0.0 | 2.0 | 0.0 |
      | BP-XX2 | 0.0 | 0.0 | 4.0 | 0.0 |

  Scenario Outline: Fuel use coefficients committee from aircraft missing fuel use coefficients
    Given a flight emitter
    And a characteristic "aircraft.bp_code" of "<code>"
    When the "aircraft_class" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should have a record with "m3" equal to "0.0"
    And the conclusion of the committee should have a record with "m2" equal to "0.0"
    And the conclusion of the committee should have a record with "m1" equal to "4"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "0.0"
    Examples:
      | code    |
      | BP-XX1f |
      | BP-XX3  |
      | BP-XX4  |

  Scenario: Fuel use coefficients committee from aircraft class
    Given a flight emitter
    And a characteristic "aircraft_class.code" of "EX"
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should have a record with "m3" equal to "0.0"
    And the conclusion of the committee should have a record with "m2" equal to "0.0"
    And the conclusion of the committee should have a record with "m1" equal to "1.75"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "0.0"

  Scenario Outline: Fuel use coefficients from various cohorts
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin_iata>"
    And a characteristic "destination_airport.iata_code" of "<destination_iata>"
    And a characteristic "airline.iata_code" of "<airline_iata>"
    When the "cohort" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "<b>"
    Examples:
      | origin_iata | destination_iata | airline_iata | m3  | m2  | m1      | b   |
      | AIA         |                  |              | 0.0 | 0.0 | 2.66667 | 0.0 |
      |             | WEA              |              | 0.0 | 0.0 | 2.66667 | 0.0 |
      |             |                  | DA           | 0.0 | 0.0 | 1.5     | 0.0 |
      | AIA         |                  | EA           | 0.0 | 0.0 | 4.0     | 0.0 |
      # some aircraft missing fuel use equation
      # some aircraft missing fuel use equation
      # all aircraft have fuel use equation
      # all aircraft missing fuel use equation

  Scenario: Fuel use coefficients committee from default
    Given a flight emitter
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should have a record with "m3" equal to "0.0"
    And the conclusion of the committee should have a record with "m2" equal to "0.0"
    And the conclusion of the committee should have a record with "m1" equal to "1.4"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "0.0"

  Scenario: Dogleg factor committee from segments per trip
    Given a flight emitter
    And a characteristic "segments_per_trip" of "2"
    When the "dogleg_factor" committee is calculated
    Then the committee should have used quorum "from segments per trip"
    And the conclusion of the committee should be "1.25"

  Scenario: Dogleg factor committee from default segments per trip
    Given a flight emitter
    When the "segments_per_trip" committee is calculated
    And the "dogleg_factor" committee is calculated
    Then the committee should have used quorum "from segments per trip"
    And the conclusion of the committee should be "1.16126"

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

  Scenario: Distance committee from cohort based on origin
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "AIA"
    When the "cohort" committee is calculated
    And the "distance" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "1000.0"

  Scenario: Distance committee from cohort based on destination
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "destination_airport.iata_code" of "WEA"
    When the "cohort" committee is calculated
    And the "distance" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "1000.0"

  Scenario Outline: Distance committee from cohort based on aircraft/airline
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "aircraft.bp_code" of "<aircraft_code>"
    And a characteristic "airline.iata_code" of "<airline_iata>"
    When the "cohort" committee is calculated
    And the "distance" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | aircraft_code | airline_iata | distance |
      | BP-FM1        |              | 100.0    |
      |               | DA           | 100.0    |

  Scenario: Distance committee from default
    Given a flight emitter
    When the "distance" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "640.0"

  Scenario Outline: Adjusted distance committee from distance, route inefficiency factor, and dogleg factor
    Given a flight emitter
    And a characteristic "distance" of "<distance>"
    And a characteristic "route_inefficiency_factor" of "<route_factor>"
    And a characteristic "dogleg_factor" of "<dogleg>"
    When the "adjusted_distance" committee is calculated
    Then the conclusion of the committee should be "<adj_dist>"
    Examples:
      | distance | route_factor | dogleg  | adj_dist  |
      | 100      | 1.1          | 1.25    | 137.5     |
      | 640      | 1.1          | 1.16126 | 817.52704 |

  Scenario Outline: Adjusted distance per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance" of "<adj_dist>"
    And a characteristic "segments_per_trip" of "<segments>"
    When the "adjusted_distance_per_segment" committee is calculated
    Then the conclusion of the committee should be "<adj_d_per_s>"
    Examples:
      | adj_dist  | segments | adj_d_per_s |
      | 100       | 2        | 50          |
      | 817.52749 | 1.67     | 489.53742   |

  Scenario: Fuel per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "100"
    And a characteristic "aircraft.bp_code" of "BP-BA1"
    When the "fuel_use_coefficients" committee is calculated
    And the "fuel_per_segment" committee is calculated
    Then the conclusion of the committee should be "200"

  Scenario: Fuel per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "489.53742"
    When the "fuel_use_coefficients" committee is calculated
    And the "fuel_per_segment" committee is calculated
    Then the conclusion of the committee should be "685.35239"

  Scenario Outline: Fuel committee
    Given a flight emitter
    And a characteristic "fuel_per_segment" of "<fuel_per_s>"
    And a characteristic "segments_per_trip" of "<segments>"
    And a characteristic "trips" of "<trips>"
    When the "fuel" committee is calculated
    Then the conclusion of the committee should be "<fuel>"
    Examples:
      | fuel_per_s | segments | trips   | fuel       |
      | 100        | 2        | 2       | 400        |
      | 685.35239  | 1.67     | 1.94100 | 2221.54921 |

  Scenario: Aviation multiplier committee from default
    Given a flight emitter
    When the "aviation_multiplier" committee is calculated
    Then the conclusion of the committee should be "2"

  Scenario: Emission factor committee from default fuel type
    Given a flight emitter
    When the "fuel_type" committee is calculated
    And the "emission_factor" committee is calculated
    Then the conclusion of the committee should be "1.0"
