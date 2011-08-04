Feature: Flight Committee Calculations
  The flight model should generate correct committee calculations

  Scenario: Date committee from timeframe
    Given a flight emitter
    And a characteristic "timeframe" of "2010-07-15/2010-07-20"
    When the "date" committee reports
    Then the conclusion of the committee should be "2010-07-15"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Segments per trip committee from default
    Given a flight emitter
    When the "segments_per_trip" committee reports
    Then the conclusion of the committee should be "1.68"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Cohort committee from various characteristics
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "date" committee reports
    And the "cohort" committee reports
    Then the conclusion of the committee should have a record with "count" equal to "<records>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | origin | dest | aircraft       | airline   | records | comment                        |
      | JFK    |      |                |           | 3       | origin with just BTS segments  |
      | FRA    |      |                |           | 1       | origin with just ICAO segments |
      | LHR    |      |                |           | 2       | origin with BTS and ICAO segments |
      |        | JFK  |                |           | 3       | dest with just BTS segments |
      |        | FRA  |                |           | 1       | dest with just ICAO segments |
      |        | LHR  |                |           | 3       | dest with BTS and ICAO segments |
      |        |      | boeing 737-400 |           | 3       | aircraft with simple description |
      |        |      | boeing 737-200 |           | 3       | aircraft with simple and complex descriptions |
      |        |      |                | Lufthansa | 2       | airline |
      | JFK    | LHR  |                |           | 2       | origin US destination foreign (BTS) |
      | LHR    | JFK  |                |           | 1       | origin foreign destination US (BTS) |
      | FRA    | LHR  |                |           | 1       | origin/destination foreign (ICAO) |
      | JFK    | ATL  |                | Delta     | 2       | origin/destination + airline but destination not in flight segments |
      | JFK    | FRA  |                |           | 2       | origin + dest don't match; origin or dest in US, origin has BTS segments only |
      | FRA    | FRA  |                |           | 1       | origin + dest don't match; origin + dest not in US, origin has ICAO segments only |

  Scenario: Cohort committee from origin and date
    Given a flight emitter
    And a characteristic "timeframe" of "2009-01-01/2010-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "JFK"
    When the "date" committee reports
    And the "cohort" committee reports
    Then the conclusion of the committee should have a record with "count" equal to "1"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Cohort committe from various unusable characteristics
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "<segments>"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "date" committee reports
    And the "cohort" committee reports
    Then the conclusion of the committee should be nil
    Examples:
      | segments | origin | dest | aircraft       | airline | comment |
      | 2        | JFK    | LHR  |                |         | indirect flight |
      | 1        | FRA    | JFK  |                |         | origin and dest don't match, origin or dest in US, origin has no BTS segments |
      | 1        | MEX    | FRA  |                |         | origin and dest don't match, neither in US, origin has no ICAO segments |
      | 1        | ATL    |      |                |         | origin exists but not in flight segments |
      | 1        | XXX    |      |                |         | origin does not exist |
      | 1        |        | ATL  |                |         | dest exists but not in flight segments |
      | 1        |        |      | boeing 737-500 |         | aircraft exists but not in flight segments |
      | 1        |        |      |                | KLM     | airline exists but not in flight segments |
      | 1        | ATL    | LHR  |                | Delta   | origin not in flight segments, destination + airline in flight segments |
      | 1        |        | SFO  |                |         | valid destination only but only segments with zero passengers |
      # | 1        | LGA    | SFO  |                |         | valid origin/destination but only segments with zero passengers |

  Scenario: Country committee from origin and destination
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "JFK"
    And a characteristic "destination_airport.iata_code" of "ATL"
    When the "country" committee reports
    Then the conclusion of the committee should have "iso_3166_code" of "US"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Country committee from origin only
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "JFK"
    When the "country" committee reports
    Then the conclusion of the committee should be nil

  Scenario: Country committee for international flight
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "LHR"
    And a characteristic "destination_airport.iata_code" of "FRA"
    When the "country" committee reports
    Then the conclusion of the committee should be nil

  Scenario: Trips committee from default
    Given a flight emitter
    When the "trips" committee reports
    Then the conclusion of the committee should be "1.7"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Freight share committee from cohort
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "date" committee reports
    And the "cohort" committee reports
    And the "freight_share" committee reports
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<freight_share>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | origin | dest | aircraft       | airline   | freight_share |
      | JFK    |      |                |           | 0.03286       |
      | FRA    |      |                |           | 0.05          |
      | LHR    |      |                |           | 0.04348       |
      |        | JFK  |                |           | 0.04          |
      |        | FRA  |                |           | 0.05          |
      |        | LHR  |                |           | 0.03957       |
      |        |      | boeing 737-400 |           | 0.03957       |
      |        |      | boeing 737-200 |           | 0.03500       |
      |        |      |                | Lufthansa | 0.05          |
      | JFK    | LHR  |                |           | 0.03286       |
      | LHR    | JFK  |                |           | 0.04          |
      | FRA    | LHR  |                |           | 0.05          |
      | JFK    | ATL  |                | Delta     | 0.03286       |
      | JFK    | FRA  |                |           | 0.03286       |
      | FRA    | FRA  |                |           | 0.05          |
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

  Scenario: Freight share committee from default
    Given a flight emitter
    When the "freight_share" committee reports
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "0.04053"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Load factor committee from cohort
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "date" committee reports
    And the "cohort" committee reports
    And the "load_factor" committee reports
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<load_factor>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | origin | dest | aircraft       | airline   | load_factor |
      | JFK    |      |                |           | 0.86429     |
      | FRA    |      |                |           | 0.9         |
      | LHR    |      |                |           | 0.76739     |
      |        | JFK  |                |           | 0.77581     |
      |        | FRA  |                |           | 0.8         |
      |        | LHR  |                |           | 0.87826     |
      |        |      | boeing 737-400 |           | 0.87826     |
      |        |      | boeing 737-200 |           | 0.8         |
      |        |      |                | Lufthansa | 0.875       |
      | JFK    | LHR  |                |           | 0.86429     |
      | LHR    | JFK  |                |           | 0.75        |
      | FRA    | LHR  |                |           | 0.9         |
      | JFK    | ATL  |                | Delta     | 0.86429     |
      | JFK    | FRA  |                |           | 0.86429     |
      | FRA    | FRA  |                |           | 0.9         |
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

  Scenario: Load factor committee from default
    Given a flight emitter
    When the "load_factor" committee reports
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "0.84037"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Seats committee from seats estimate
    Given a flight emitter
    And a characteristic "seats_estimate" of "100.75"
    When the "seats" committee reports
    Then the committee should have used quorum "from seats estimate"
    And the conclusion of the committee should be "100"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Seats committee from cohort
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "airline.name" of "<airline>"
    When the "date" committee reports
    And the "cohort" committee reports
    And the "seats" committee reports
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<seats>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
    | origin | dest | airline   | seats     |
    | JFK    |      |           | 153.57143 |
    | FRA    |      |           | 400       |
    | LHR    |      |           | 247.82609 |
    |        | JFK  |           | 300       |
    |        | FRA  |           | 150       |
    |        | LHR  |           | 250       |
    |        |      | Lufthansa | 337.5     |
    | JFK    | LHR  |           | 153.57143 |
    | LHR    | JFK  |           | 300       |
    | FRA    | LHR  |           | 400       |
    | JFK    | ATL  | Delta     | 153.57143 |
    | JFK    | FRA  |           | 153.57143 |
    | FRA    | FRA  |           | 400       |
    # origin with just BTS segments
    # origin with just ICAO segments
    # origin with BTS and ICAO segments
    # dest with just BTS segments
    # dest with just ICAO segments
    # dest with BTS and ICAO segments
    # airline
    # origin US destination foreign (BTS)
    # origin foreign destination US (BTS)
    # origin/destination foreign (ICAO)
    # origin/destination + airline but destination not in flight segments
    # origin + dest don't match; origin or dest in US, origin has BTS segments only
    # origin + dest don't match; origin + dest not in US, origin has ICAO segments only

  Scenario Outline: Seats committee from aircraft with seats
    Given a flight emitter
    And a characteristic "aircraft.description" of "<aircraft>"
    When the "seats" committee reports
    Then the committee should have used quorum "from aircraft"
    And the conclusion of the committee should be "<seats>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | aircraft       | seats |
      | boeing 737-100 | 212.5 |
      | boeing 737-400 | 250   |

  Scenario: Seats committee from aircraft missing seats
    Given a flight emitter
    And a characteristic "aircraft.description" of "boeing 737-500"
    When the "aircraft_class" committee reports
    And the "seats" committee reports
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should be "249.54955"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Seats committee from default
    Given a flight emitter
    When the "seats" committee reports
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "257.47508"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Passengers committee from seats and load factor
    Given a flight emitter
    And a characteristic "seats" of "<seats>"
    And a characteristic "load_factor" of "<load_factor>"
    When the "passengers" committee reports
    Then the conclusion of the committee should be "<passengers>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | seats | load_factor | passengers |
      | 105   | 0.9         | 95.0       |
      | 123   | 0.81385     | 100.0      |

  Scenario: Fuel committee from default
    Given a flight emitter
    When the "fuel" committee reports
    Then the conclusion of the committee should have "name" of "Jet Fuel"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Fuel use coefficients from various cohorts
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    When the "date" committee reports
    And the "cohort" committee reports
    And the "fuel_use_coefficients" committee reports
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "b" equal to "<b>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | origin | dest | m3  | m2  | m1      | b   |
      | FRA    |      | 0.0 | 0.0 | 2.0     | 0.0 |
      | JFK    | LHR  | 0.0 | 0.0 | 1.85023 | 0.0 |
      | LHR    | JFK  | 0.0 | 0.0 | 1.74194 | 0.0 |
      # all aircraft have fuel use equation
      # some aircraft missing fuel use equation
      # all aircraft missing fuel use equation but have aircraft class fuel use equation

  Scenario: Fuel use coefficients from cohorts where no aircraft have fuel use equation
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "MEX"
    And a characteristic "destination_airport.iata_code" of "JFK"
    When the "date" committee reports
    And the "cohort" committee reports
    And the "fuel_use_coefficients" committee reports
    Then the committee should have used quorum "default"
    And the conclusion of the committee should have a record with "m3" equal to "0.0"
    And the conclusion of the committee should have a record with "m2" equal to "0.0"
    And the conclusion of the committee should have a record with "m1" equal to "1.74194"
    And the conclusion of the committee should have a record with "b" equal to "0.0"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Fuel use coefficients committee from aircraft with fuel use coefficients
    Given a flight emitter
    And a characteristic "aircraft.description" of "<aircraft>"
    When the "fuel_use_coefficients" committee reports
    Then the committee should have used quorum "from aircraft"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "b" equal to "<b>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | aircraft       | m3  | m2  | m1  | b   |
      | boeing 737-100 | 0.0 | 0.0 | 1.0 | 0.0 |
      | boeing 737-400 | 0.0 | 0.0 | 2.0 | 0.0 |

  Scenario Outline: Fuel use coefficients committee from aircraft missing fuel use coefficients
    Given a flight emitter
    And a characteristic "aircraft.description" of "<aircraft>"
    When the "aircraft_class" committee reports
    And the "fuel_use_coefficients" committee reports
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should have a record with "m3" equal to "0.0"
    And the conclusion of the committee should have a record with "m2" equal to "0.0"
    And the conclusion of the committee should have a record with "m1" equal to "1.74194"
    And the conclusion of the committee should have a record with "b" equal to "0.0"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | aircraft       |
      | boeing 737-300 |

  Scenario: Fuel use coefficients committee from default
    Given a flight emitter
    When the "fuel_use_coefficients" committee reports
    Then the committee should have used quorum "default"
    And the conclusion of the committee should have a record with "m3" equal to "0.0"
    And the conclusion of the committee should have a record with "m2" equal to "0.0"
    And the conclusion of the committee should have a record with "m1" equal to "1.74194"
    And the conclusion of the committee should have a record with "b" equal to "0.0"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Dogleg factor committee from segments per trip
    Given a flight emitter
    And a characteristic "segments_per_trip" of "2"
    When the "dogleg_factor" committee reports
    Then the committee should have used quorum "from segments per trip"
    And the conclusion of the committee should be "1.25"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Dogleg factor committee from default segments per trip
    Given a flight emitter
    When the "segments_per_trip" committee reports
    And the "dogleg_factor" committee reports
    Then the committee should have used quorum "from segments per trip"
    And the conclusion of the committee should be "1.16385"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Route inefficiency factor committee from country
    Given a flight emitter
    And a characteristic "country.iso_3166_code" of "US"
    When the "route_inefficiency_factor" committee reports
    Then the committee should have used quorum "from country"
    And the conclusion of the committee should be "1.1"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Route inefficiency factor committee from default
    Given a flight emitter
    When the "route_inefficiency_factor" committee reports
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1.2"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Route inefficiency factor after country committee has returned nil
    Given a flight emitter
    When the "country" committee reports
    And the "route_inefficiency_factor" committee reports
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1.2"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Distance committee from airports
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    When the "distance" committee reports
    Then the committee should have used quorum "from airports"
    And the conclusion of the committee should be "<distance>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | origin | dest | distance |
      | LHR    | JFK  | 1000.0   |
      | LHR    | FRA  |  100.0   |

  Scenario: Distance committee from distance estimate
    Given a flight emitter
    And a characteristic "distance_estimate" of "185.2"
    When the "distance" committee reports
    Then the committee should have used quorum "from distance estimate"
    And the conclusion of the committee should be "100.0"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Distance committee from distance class
    Given a flight emitter
    And a characteristic "distance_class.name" of "short haul"
    When the "distance" committee reports
    Then the committee should have used quorum "from distance class"
    And the conclusion of the committee should be "100.0"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Distance committee from cohort based on origin only
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "JFK"
    When the "date" committee reports
    And the "cohort" committee reports
    And the "distance" committee reports
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "1000.0"
    And the conclusion should not comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Distance committee from cohort based on destination only
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "destination_airport.iata_code" of "FRA"
    When the "date" committee reports
    And the "cohort" committee reports
    And the "distance" committee reports
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "100.0"
    And the conclusion should not comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Distance committee from cohort based on airline / aircraft
    Given a flight emitter
    And a characteristic "timeframe" of "2011-01-01/2012-01-01"
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "date" committee reports
    And the "cohort" committee reports
    And the "distance" committee reports
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<distance>"
    And the conclusion should not comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | aircraft       | airline   | distance |
      | boeing 737-100 |           | 662.5    |
      |                | Lufthansa | 100.0    |

  Scenario: Distance committee from default
    Given a flight emitter
    When the "distance" committee reports
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "792.69103"
    And the conclusion should not comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Adjusted distance committee from distance, route inefficiency factor, and dogleg factor
    Given a flight emitter
    And a characteristic "distance" of "<distance>"
    And a characteristic "route_inefficiency_factor" of "<route_factor>"
    And a characteristic "dogleg_factor" of "<dogleg>"
    When the "adjusted_distance" committee reports
    Then the conclusion of the committee should be "<adj_dist>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | distance | route_factor | dogleg  | adj_dist  |
      | 100      | 1.1          | 1.25    | 137.5     |
      | 640      | 1.1          | 1.16126 | 817.52704 |

  Scenario Outline: Adjusted distance per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance" of "<adj_dist>"
    And a characteristic "segments_per_trip" of "<segments>"
    When the "adjusted_distance_per_segment" committee reports
    Then the conclusion of the committee should be "<adj_d_per_s>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | adj_dist  | segments | adj_d_per_s |
      | 100       | 2        | 50          |
      | 817.52749 | 1.67     | 489.53742   |

  Scenario Outline: Seat class multiplier committee from adjusted distance per segment
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "<distance>"
    When the "seat_class_multiplier" committee reports
    Then the committee should have used quorum "from adjusted distance per segment"
    And the conclusion of the committee should be "<multiplier>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | distance | multiplier |
      | 1        | 1.0        |
      | 245      | 1.0        |
      | 864      | 1.0        |
      | 9000     | 1.0        |

  Scenario Outline: Seat class multiplier committee from adjusted distance per segment and seat class name
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "<distance>"
    And a characteristic "seat_class_name" of "<seat_class>"
    When the "seat_class_multiplier" committee reports
    Then the committee should have used quorum "from seat class name and adjusted distance per segment"
    And the conclusion of the committee should be "<multiplier>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | distance | seat_class     | multiplier |
      | 1        | unknown        | 1.0        |
      | 244      | unknown        | 1.0        |
      | 245      | unknown        | 1.0        |
      | 500      | economy        | 0.9706     |
      | 863      | first/business | 1.4410     |
      | 864      | unknown        | 1.0        |
      | 1000     | economy        | 0.7294     |
      | 2000     | economy+       | 1.1680     |
      | 3000     | business       | 2.1160     |
      | 4000     | first          | 3.4360     |

  Scenario: Fuel per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "100"
    And a characteristic "aircraft.description" of "boeing 737-400"
    When the "fuel_use_coefficients" committee reports
    And the "fuel_per_segment" committee reports
    Then the conclusion of the committee should be "200"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Fuel per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "1000"
    When the "fuel_use_coefficients" committee reports
    And the "fuel_per_segment" committee reports
    Then the conclusion of the committee should be "1741.93548"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario Outline: Fuel use committee
    Given a flight emitter
    And a characteristic "fuel_per_segment" of "<fuel_per_s>"
    And a characteristic "segments_per_trip" of "<segments>"
    And a characteristic "trips" of "<trips>"
    When the "fuel_use" committee reports
    Then the conclusion of the committee should be "<fuel_use>"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
    Examples:
      | fuel_per_s | segments | trips   | fuel_use   |
      | 100        | 2        | 2       | 400        |
      | 685.35239  | 1.67     | 1.94100 | 2221.54921 |

  Scenario: Aviation multiplier committee from default
    Given a flight emitter
    When the "aviation_multiplier" committee reports
    Then the conclusion of the committee should be "2"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Emission factor from fuel
    Given a flight emitter
    And a characteristic "fuel.name" of "Aviation Gasoline"
    When the "emission_factor" committee reports
    Then the conclusion of the committee should be "3.14286"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"

  Scenario: Emission factor committee from default fuel
    Given a flight emitter
    When the "fuel" committee reports
    And the "emission_factor" committee reports
    Then the conclusion of the committee should be "3.25"
    And the conclusion should comply with standards "ghg_protocol_scope_3, iso, tcr"
