Feature: Flight Committee Calculations
  The flight model should generate correct committee calculations

  Scenario: Cohort committee from t100 with usable characteristics
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "DTW"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should have a record with "count" equal to "34"

  Scenario: Cohort committee from t100 with no usable characteristics
    Given a flight emitter
    And a characteristic "seat_class.name" of "business"
    When the "cohort" committee is calculated
    Then the conclusion of the committee should be nil

  Scenario Outline: Date committee from timeframe
    Given a flight emitter
    And a characteristic "timeframe" of "<timeframe>"
    When the "date" committee is calculated
    Then the committee should have used quorum "from timeframe"
    And the conclusion of the committee should be "<from>"
    Examples:
      | timeframe             | from       |
      | 2010-07-15/2010-07-20 | 2010-07-15 |

  Scenario Outline: Date committee from nil timeframe
    Given a flight emitter
    And a characteristic "timeframe" of "<timeframe>"
    When the "date" committee is calculated
    Then the conclusion of the committee should be "<from>"
    Examples:
      | timeframe             | from       |
      |                       |            |

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
      | business   | 1.69       |
      | economy    | 0.94       |
      | first      | 1.47       |

  Scenario: Seat class multiplier committee from default
    Given a flight emitter
    When the "seat_class_multiplier" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1.0"

  Scenario: Trips committee
    Given a flight emitter
    When the "trips" committee is calculated
    Then the conclusion of the committee should be "1.941"

  Scenario: Freight share committee from cohort
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "DTW"
    When the "cohort" committee is calculated
    And the "freight_share" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "0.11876"

  Scenario: Fuel type committee from default
    Given a flight emitter
    When the "fuel_type" committee is calculated
    Then the conclusion of the committee should have a record with "emission_factor" equal to "2.527139"

  Scenario Outline: Emission factor committee
    Given a flight emitter
    And pending - no fuel type records yet

  Scenario Outline: Radiative forcing index committee
    Given a flight emitter
    And pending - no fuel type records yet

  Scenario Outline: Radiative forcing index committee
    Given a flight emitter
    And pending - no fuel type records yet

  Scenario: Emplanements per trip committee from default
    Given a flight emitter
    When the "emplanements_per_trip" committee is calculated
    Then the conclusion of the committee should be "1.67"

  Scenario: Distance committee from default
    Given a flight emitter
    When the "distance" committee is calculated
    Then the committee should have used quorum "default"
    And the conclusion of the committee should be "1121.73083"

  Scenario Outline: Distance committee from cohort
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<destination>"
    And a characteristic "aircraft.icao_code" of "<craft>"
    And a characteristic "airline.iata_code" of "<airline>"
    And a characteristic "propulsion.name" of "<propulsion>"
    And a characteristic "domesticity.name" of "<domesticity>"
    When the "cohort" committee is calculated
    And the "distance" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | origin | destination | craft | airline | propulsion | domesticity                     | distance |
      |    DTW |             | A320  | UA      |            | Domestic Data, US Carriers Only |   325    |

  Scenario Outline: Distance committee from distance class
    Given a flight emitter
    And a characteristic "distance_class.name" of "<distance_class>"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from distance class"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | distance_class | distance   |
      |           epic | 8689.74081 |
      |           long | 2606.92764 |
      |         medium |  868.97408 |
      |          short |  217.24406 |

  Scenario Outline: Distance committee from distance estimate
    Given a flight emitter
    And a characteristic "distance_estimate" of "<distance_estimate>"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from distance estimate"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | distance_estimate | distance |
      |               123 | 66.41468 |

  Scenario Outline: Distance committee from airports
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<destination>"
    When the "distance" committee is calculated
    Then the committee should have used quorum "from airports"
    And the conclusion of the committee should be "<distance>"
    Examples:
      | origin | destination | distance   |
      |    DTW |         SFO | 1803.65517 |
      |    IAD |         DCA |   20.32743 |
      |    MSP |         FRA | 3809.26855 |

  Scenario Outline: Adjusted distance committee from distance
    Given a flight emitter
    And a characteristic "distance_estimate" of "<distance_estimate>"
    When the "distance" committee is calculated
    And the "emplanements_per_trip" committee is calculated
    And the "adjusted_distance" committee is calculated
    Then the conclusion of the committee should be "<distance>"
    Examples:
      | distance_estimate | distance  |
      |                 0 |         0 |
      |                 1 |   0.67092 |
      |              1254 | 841.33709 |
