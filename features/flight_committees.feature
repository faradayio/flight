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
    Then the conclusion of the committee should be "1.68"

  Scenario Outline: Cohort committee from various characteristics
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "<records>"
    Examples:
      | origin | dest | aircraft       | airline         | records |
      | JFK    |      |                |                 | 2       |
      | FRA    |      |                |                 | 1       |
      | LHR    |      |                |                 | 2       |
      |        | JFK  |                |                 | 2       |
      |        | FRA  |                |                 | 1       |
      |        | LHR  |                |                 | 3       |
      |        |      | boeing 737-400 |                 | 3       |
      |        |      | boeing 737-200 |                 | 3       |
      |        |      |                | British Airways | 2       |
      | JFK    | LHR  |                |                 | 2       |
      | LHR    | JFK  |                |                 | 1       |
      | FRA    | LHR  |                |                 | 1       |
      | JFK    | ATL  | boeing 737-400 |                 | 2       |
      | JFK    | FRA  |                |                 | 2       |
      | FRA    | FRA  |                |                 | 1       |
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

  Scenario Outline: Cohort committe from various unusable characteristics
    Given a flight emitter
    And a characteristic "segments_per_trip" of "<segments>"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil
    Examples:
      | segments | origin | dest | aircraft       | airline         |
      | 2        | JFK    | LHR  |                |                 |
      | 1        | FRA    | JFK  |                |                 |
      | 1        | MEX    | FRA  |                |                 |
      | 1        | ATL    |      |                |                 |
      | 1        | XXX    |      |                |                 |
      | 1        |        | ATL  |                |                 |
      | 1        |        |      | boeing 737-500 |                 |
      | 1        |        |      |                | Lufthansa       |
      | 1        | ATL    | LHR  |                | British Airways |
      | 1        | LGA    | SFO  |                |                 |
      | 1        |        | SFO  |                |                 |
      # indirect flight
      # origin and dest don't match, origin or dest in US, origin has no BTS segments
      # origin and dest don't match, neither in US, origin has no ICAO segments
      # origin exists but not in flight segments
      # origin does not exist
      # dest exists but not in flight segments
      # aircraft exists but not in flight segments
      # airline exists but not in flight segments
      # origin not in flight segments, destination + airline in flight segments
      # valid origin/destination but only segments with zero passengers
      # valid destination only but only segments with zero passengers

  Scenario: Country committee from origin and destination
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "JFK"
    And a characteristic "destination_airport.iata_code" of "ATL"
    When the "country" committee is calculated
    Then the conclusion of the committee should have "iso_3166_code" of "US"

  Scenario: Country committee from origin only
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "JFK"
    When the "country" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Country committee for international flight
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "LHR"
    And a characteristic "destination_airport.iata_code" of "FRA"
    When the "country" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario: Trips committee from default
    Given a flight emitter
    When the "trips" committee is calculated
    Then the conclusion of the committee should be "1.7"

  Scenario Outline: Freight share committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "cohort" committee is calculated
    And the "freight_share" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<freight_share>"
    Examples:
      | origin | dest | aircraft       | airline         | freight_share |
      | JFK    |      |                |                 | 0.03286       |
      | FRA    |      |                |                 | 0.05          |
      | LHR    |      |                |                 | 0.04348       |
      |        | JFK  |                |                 | 0.04          |
      |        | FRA  |                |                 | 0.05          |
      |        | LHR  |                |                 | 0.03957       |
      |        |      | boeing 737-400 |                 | 0.03957       |
      |        |      | boeing 737-200 |                 | 0.03500       |
      |        |      |                | British Airways | 0.05          |
      | JFK    | LHR  |                |                 | 0.03286       |
      | LHR    | JFK  |                |                 | 0.04          |
      | FRA    | LHR  |                |                 | 0.05          |
      | JFK    | ATL  | boeing 737-400 |                 | 0.03286       |
      | JFK    | FRA  |                |                 | 0.03286       |
      | FRA    | FRA  |                |                 | 0.05          |
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
    When the "freight_share" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "0.04053"

  Scenario Outline: Load factor committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "cohort" committee is calculated
    And the "load_factor" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<load_factor>"
    Examples:
      | origin | dest | aircraft       | airline         | load_factor |
      | JFK    |      |                |                 | 0.86429     |
      | FRA    |      |                |                 | 0.9         |
      | LHR    |      |                |                 | 0.76739     |
      |        | JFK  |                |                 | 0.77581     |
      |        | FRA  |                |                 | 0.8         |
      |        | LHR  |                |                 | 0.87826     |
      |        |      | boeing 737-400 |                 | 0.87826     |
      |        |      | boeing 737-200 |                 | 0.8         |
      |        |      |                | British Airways | 0.875       |
      | JFK    | LHR  |                |                 | 0.86429     |
      | LHR    | JFK  |                |                 | 0.75        |
      | FRA    | LHR  |                |                 | 0.9         |
      | JFK    | ATL  | boeing 737-400 |                 | 0.86429     |
      | JFK    | FRA  |                |                 | 0.86429     |
      | FRA    | FRA  |                |                 | 0.9         |
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
    When the "load_factor" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "0.84037"

  Scenario: Seats committee from seats estimate
    Given a flight emitter
    And a characteristic "seats_estimate" of "100.75"
    When the "seats" committee is calculated
    Then the committee should have used quorum "from seats estimate"
    And the conclusion of the committee should be "100"

  Scenario Outline: Seats committee from cohort
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "cohort" committee is calculated
    And the "seats" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<seats>"
    Examples:
    | origin | dest | aircraft       | airline         | seats     |
    | JFK    |      |                |                 | 153.57143 |
    | FRA    |      |                |                 | 400       |
    | LHR    |      |                |                 | 247.82609 |
    |        | JFK  |                |                 | 300       |
    |        | FRA  |                |                 | 150       |
    |        | LHR  |                |                 | 250       |
    |        |      | boeing 737-400 |                 | 250       |
    |        |      | boeing 737-200 |                 | 250       |
    |        |      |                | British Airways | 337.5     |
    | JFK    | LHR  |                |                 | 153.57143 |
    | LHR    | JFK  |                |                 | 300       |
    | FRA    | LHR  |                |                 | 400       |
    | JFK    | ATL  | boeing 737-400 |                 | 153.57143 |
    | JFK    | FRA  |                |                 | 153.57143 |
    | FRA    | FRA  |                |                 | 400       |
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

  Scenario Outline: Seats committee from aircraft with seats
    Given a flight emitter
    And a characteristic "aircraft.description" of "<aircraft>"
    When the "seats" committee is calculated
    Then the committee should have used quorum "from aircraft"
    And the conclusion of the committee should be "<seats>"
    Examples:
      | aircraft       | seats |
      | boeing 737-100 | 212.5 |
      | boeing 737-400 | 250   |

  Scenario: Seats committee from aircraft missing seats
    Given a flight emitter
    And a characteristic "aircraft.description" of "boeing 737-500"
    When the "aircraft_class" committee is calculated
    And the "seats" committee is calculated
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should be "249.54955"

  Scenario: Seats committee from default
    Given a flight emitter
    When the "seats" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "257.47508"

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

  Scenario: Fuel committee from default
    Given a flight emitter
    When the "fuel" committee is calculated
    Then the conclusion of the committee should have "name" of "Jet Fuel"

  Scenario Outline: Fuel use coefficients from various cohorts
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    And a characteristic "airline.name" of "<airline>"
    When the "cohort" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "b" equal to "<b>"
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
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "MEX"
    And a characteristic "destination_airport.iata_code" of "JFK"
    When the "cohort" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should have a record with "m3" equal to "0.0"
    And the conclusion of the committee should have a record with "m2" equal to "0.0"
    And the conclusion of the committee should have a record with "m1" equal to "1.74194"
    And the conclusion of the committee should have a record with "b" equal to "0.0"


  Scenario Outline: Fuel use coefficients committee from aircraft with fuel use coefficients
    Given a flight emitter
    And a characteristic "aircraft.description" of "<aircraft>"
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from aircraft"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "b" equal to "<b>"
    Examples:
      | aircraft       | m3  | m2  | m1  | b   |
      | boeing 737-100 | 0.0 | 0.0 | 1.0 | 0.0 |
      | boeing 737-400 | 0.0 | 0.0 | 2.0 | 0.0 |

  Scenario Outline: Fuel use coefficients committee from aircraft missing fuel use coefficients
    Given a flight emitter
    And a characteristic "aircraft.description" of "<aircraft>"
    When the "aircraft_class" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should have a record with "m3" equal to "0.0"
    And the conclusion of the committee should have a record with "m2" equal to "0.0"
    And the conclusion of the committee should have a record with "m1" equal to "1.74194"
    And the conclusion of the committee should have a record with "b" equal to "0.0"
    Examples:
      | aircraft       |
      | boeing 737-300 |

  Scenario: Fuel use coefficients committee from default
    Given a flight emitter
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should have a record with "m3" equal to "0.0"
    And the conclusion of the committee should have a record with "m2" equal to "0.0"
    And the conclusion of the committee should have a record with "m1" equal to "1.74194"
    And the conclusion of the committee should have a record with "b" equal to "0.0"

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
    And the conclusion of the committee should be "1.16385"

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
    And the conclusion of the committee should be "1.2"

  Scenario: Route inefficiency factor after country committee has returned nil
    Given a flight emitter
    When the "country" committee is calculated
    And the "route_inefficiency_factor" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1.2"

  Scenario Outline: Distance committee from airports
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<dest>"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from airports"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | origin | dest | distance |
      | LHR    | JFK  | 1000.0   |
      | LHR    | FRA  |  100.0   |

  Scenario: Distance committee from distance estimate
    Given a flight emitter
    And a characteristic "distance_estimate" of "185.2"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from distance estimate"
    And the conclusion of the committee should be "100.0"

  Scenario: Distance committee from distance class
    Given a flight emitter
    And a characteristic "distance_class.name" of "short haul"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from distance class"
    And the conclusion of the committee should be "100.0"

  Scenario: Distance committee from cohort based on origin only
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "origin_airport.iata_code" of "JFK"
    When the "cohort" committee is calculated
    And the "distance" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "1000.0"

  Scenario: Distance committee from cohort based on destination only
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "destination_airport.iata_code" of "FRA"
    When the "cohort" committee is calculated
    And the "distance" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "100.0"

  Scenario Outline: Distance committee from cohort based on airline / aircraft
    Given a flight emitter
    And a characteristic "segments_per_trip" of "1"
    And a characteristic "aircraft.description" of "<aircraft>"
    And a characteristic "airline.name" of "<airline>"
    When the "cohort" committee is calculated
    And the "distance" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | aircraft       | airline         | distance |
      | boeing 737-100 |                 | 662.5    |
      |                | British Airways | 100.0    |

  Scenario: Distance committee from default
    Given a flight emitter
    When the "distance" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "792.69103"

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

  Scenario Outline: Seat class multiplier committee from adjusted distance per segment
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "<distance>"
    When the "seat_class_multiplier" committee is calculated
    Then the committee should have used quorum "from adjusted distance per segment"
    And the conclusion of the committee should be "<multiplier>"
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
    When the "seat_class_multiplier" committee is calculated
    Then the committee should have used quorum "from seat class name and adjusted distance per segment"
    And the conclusion of the committee should be "<multiplier>"
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
    When the "fuel_use_coefficients" committee is calculated
    And the "fuel_per_segment" committee is calculated
    Then the conclusion of the committee should be "200"

  Scenario: Fuel per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "1000"
    When the "fuel_use_coefficients" committee is calculated
    And the "fuel_per_segment" committee is calculated
    Then the conclusion of the committee should be "1741.93548"

  Scenario Outline: Fuel use committee
    Given a flight emitter
    And a characteristic "fuel_per_segment" of "<fuel_per_s>"
    And a characteristic "segments_per_trip" of "<segments>"
    And a characteristic "trips" of "<trips>"
    When the "fuel_use" committee is calculated
    Then the conclusion of the committee should be "<fuel_use>"
    Examples:
      | fuel_per_s | segments | trips   | fuel_use   |
      | 100        | 2        | 2       | 400        |
      | 685.35239  | 1.67     | 1.94100 | 2221.54921 |

  Scenario: Aviation multiplier committee from default
    Given a flight emitter
    When the "aviation_multiplier" committee is calculated
    Then the conclusion of the committee should be "2"

  Scenario: Emission factor from fuel
    Given a flight emitter
    And a characteristic "fuel.name" of "Aviation Gasoline"
    When the "emission_factor" committee is calculated
    Then the conclusion of the committee should be "3.14286"

  Scenario: Emission factor committee from default fuel
    Given a flight emitter
    When the "fuel" committee is calculated
    And the "emission_factor" committee is calculated
    Then the conclusion of the committee should be "3.25"
