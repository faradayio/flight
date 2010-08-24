Feature: Flight Committee Calculations
  The flight model should generate correct committee calculations

  Scenario: Cohort committee from t100 with usable characteristics
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "AIA"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "1"

  Scenario: Cohort committee from t100 with no usable characteristics
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "XXX"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario Outline: Date committee from timeframe
    Given a flight emitter
    And a characteristic "timeframe" of "<timeframe>"
    When the "date" committee is calculated
    Then the committee should have used quorum "from timeframe"
    And the conclusion of the committee should be "<date>"
    Examples:
      | timeframe             | date       |
      | 2010-07-15/2010-07-20 | 2010-07-15 |

  Scenario: Date committee from nil timeframe
    Given a flight emitter
    And a characteristic "timeframe" of ""
    When the "date" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario Outline: Date committee from creation date
    Given a flight emitter
    And a characteristic "creation_date" of "<creation_date>"
    When the "date" committee is calculated
    Then the committee should have used quorum "from creation date"
    And the conclusion of the committee should be "<date>"
    Examples:
      | creation_date | date       |
      | 2010-07-15    | 2010-07-15 |

  Scenario Outline: Seat class multiplier committee from seat class
    Given a flight emitter
    And a characteristic "seat_class.name" of "<seat_class>"
    When the "seat_class_multiplier" committee is calculated
    Then the committee should have used quorum "from seat class"
    And the conclusion of the committee should be "<multiplier>"
    Examples:
      | seat_class | multiplier |
      | economy    | 1.00       |

  Scenario: Seat class multiplier committee from default
    Given a flight emitter
    When the "seat_class_multiplier" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1.0"

  Scenario: Trips committee
    Given a flight emitter
    When the "trips" committee is calculated
    Then the conclusion of the committee should be "1.941"

  Scenario Outline: Freight share committee from cohort
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    When the "cohort" committee is calculated
    And the "freight_share" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<freight share>"
    Examples:
      | origin | freight share |
      | ADA    | 0.0099        |
      | AIA    | 0.09091       |

  Scenario: Freight share committee from default
    Given a flight emitter
    When the "freight_share" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "0.06391"

  Scenario: Fuel type committee from default
    Given a flight emitter
    When the "fuel_type" committee is calculated
    Then the conclusion of the committee should have a record with "emission_factor" equal to "2.52714"

  Scenario: Emission factor committee
    Given a flight emitter
    When the "fuel_type" committee is calculated
    And the "emission_factor" committee is calculated
    Then the conclusion of the committee should be "3.1293"

  Scenario: Radiative forcing index committee
    Given a flight emitter
    When the "fuel_type" committee is calculated
    And the "radiative_forcing_index" committee is calculated
    Then the conclusion of the committee should be "2"

  Scenario: Emplanements per trip committee from default
    Given a flight emitter
    When the "emplanements_per_trip" committee is calculated
    Then the conclusion of the committee should be "1.67"

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

  Scenario Outline: Distance committee from distance estimate
    Given a flight emitter
    And a characteristic "distance_estimate" of "<distance_estimate>"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from distance estimate"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | distance_estimate | distance |
      | 185.2             | 100.0    |

  Scenario Outline: Distance committee from distance class
    Given a flight emitter
    And a characteristic "distance_class.name" of "<distance_class>"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from distance class"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | distance_class | distance |
      | petite         | 100.0    |

  Scenario Outline: Distance committee from cohort
    Given a flight emitter
    And a characteristic "airline.iata_code" of "<airline>"
    When the "cohort" committee is calculated
    And the "distance" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | airline | distance |
      | DA      |  100.0   |
      | IA      | 1000.0   |

  Scenario: Distance committee from default
    Given a flight emitter
    When the "distance" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1121.73083"

  Scenario Outline: Adjusted distance committee
    Given a flight emitter
    And a characteristic "distance_estimate" of "<distance_estimate>"
    When the "distance" committee is calculated
    And the "emplanements_per_trip" committee is calculated
    And the "adjusted_distance" committee is calculated
    Then the conclusion of the committee should be "<distance>"
    Examples:
      | distance_estimate | distance |
      | 0                 | 0        |
      | 100               | 67.09227 |

  Scenario Outline: Load factor committee from cohort
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    When the "cohort" committee is calculated
    And the "load_factor" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<load_factor>"
    Examples:
      | origin | load_factor |
      | ADA    | 0.8         |

  Scenario: Load factor committee from default
    Given a flight emitter
    When the "load_factor" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "0.86667"

  Scenario Outline: Seats committee from aircraft
    Given a flight emitter
    And a characteristic "aircraft.icao_code" of "<code>"
    When the "seats" committee is calculated
    Then the committee should have used quorum "from aircraft"
    And the conclusion of the committee should be "<seats>"
    Examples:
      | code | seats |
      | FM1  | 125   |
      | BA1  | 125   |
      | BA2  | 100   |

  Scenario: Seats committee from seats estimate
    Given a flight emitter
    And a characteristic "seats_estimate" of "100"
    When the "seats" committee is calculated
    Then the committee should have used quorum "from seats estimate"
    And the conclusion of the committee should be "100"

  Scenario Outline: Seats committee from cohort
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    When the "cohort" committee is calculated
    And the "seats" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<seats>"
    Examples:
      | origin | seats |
      | ADA    | 125   |

  Scenario: Seats committee from aircraft class
    Given a flight emitter
    And a characteristic "aircraft_class.brighter_planet_aircraft_class_code" of "EX"
    When the "seats" committee is calculated
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should be "117"

  Scenario: Seats committee from default
    Given a flight emitter
    When the "seats" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "117"

  Scenario: Passengers committee
    Given a flight emitter
    And a characteristic "seats" of "100"
    And a characteristic "load_factor" of "0.9"
    When the "passengers" committee is calculated
    Then the conclusion of the committee should be "90"

  Scenario Outline: Fuel use coefficients committee from aircraft
    Given a flight emitter
    And a characteristic "aircraft.icao_code" of "<code>"
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from aircraft"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "<b>"
    Examples:
      | code | m3 | m2 | m1 | b |
      | FM1  | 0  | 0  | 1  | 0 |
      | BA1  | 0  | 0  | 2  | 0 |

  Scenario Outline: Fuel use coefficients committee from aircraft class
    Given a flight emitter
    And a characteristic "aircraft_class.brighter_planet_aircraft_class_code" of "<code>"
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from aircraft class"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "<b>"
    Examples:
      | code | m3 | m2 | m1 | b |
      | EX   | 0  | 0  | 2  | 0 |

  Scenario Outline: Fuel use coefficients committee from cohort
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    When the "cohort" committee is calculated
    And the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "<b>"
    Examples:
      | origin | m3 | m2 | m1  | b |
      | AIA    | 0  | 0  | 2   | 0 |

  Scenario Outline: Fuel use coefficients committee from default
    Given a flight emitter
    When the "fuel_use_coefficients" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should have a record with "m3" equal to "<m3>"
    And the conclusion of the committee should have a record with "m2" equal to "<m2>"
    And the conclusion of the committee should have a record with "m1" equal to "<m1>"
    And the conclusion of the committee should have a record with "endpoint_fuel" equal to "<b>"
    Examples:
      | m3 | m2 | m1 | b |
      | 0  | 0  | 2  | 0 |

  Scenario: Adjusted distance per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance" of "100"
    And a characteristic "emplanements_per_trip" of "2"
    When the "adjusted_distance_per_segment" committee is calculated
    Then the conclusion of the committee should be "50"

  Scenario: Fuel per segment committee
    Given a flight emitter
    And a characteristic "adjusted_distance_per_segment" of "100"
    And a characteristic "aircraft_class.brighter_planet_aircraft_class_code" of "EX"
    When the "fuel_use_coefficients" committee is calculated
    And the "fuel_per_segment" committee is calculated
    Then the conclusion of the committee should be "200"

  Scenario: Fuel committee
    Given a flight emitter
    And a characteristic "fuel_per_segment" of "100"
    And a characteristic "emplanements_per_trip" of "2"
    And a characteristic "trips" of "2"
    When the "fuel" committee is calculated
    Then the conclusion of the committee should be "400"

  Scenario Outline: Emission committee from fuel and passengers and coefficients
    Given a flight emitter
    And a characteristic "fuel" of "<fuel>"
    And a characteristic "passengers" of "<passengers>"
    And a characteristic "seat_class_multiplier" of "<seat_mult>"
    And a characteristic "emission_factor" of "<ef>"
    And a characteristic "radiative_forcing_index" of "<rfi>"
    And a characteristic "freight_share" of "<freight>"
    And a characteristic "date" of "<date>"
    And a characteristic "timeframe" of "2010-01-01/2010-12-31"
    When the "emission" committee is calculated
    Then the committee should have used quorum "from fuel and passengers with coefficients"
    And the conclusion of the committee should be "<emission>"
    Examples:
      | fuel | passengers | seat_mult | ef | rfi | freight | date       | emission |
      | 100  | 100        | 1.5       | 10 | 2   | 0.10    | 2010-07-15 | 27       |

  Scenario: Emission committee from default
    Given a flight emitter
    When the "emission" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be ""
