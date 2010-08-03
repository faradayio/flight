Feature: Flight Committee Calculations
  The flight model should generate correct committee calculations

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

  Scenario Outline: Domesticity committee from airline for domestic airlines
    Given a flight emitter
    And a characteristic "airline.name" of "<airline>"
    When the "domesticity" committee is calculated
    Then the committee should have used quorum "from airline"
    And the conclusion of the committee should have a record with "name" equal to "<domesticity>"
    Examples:
      | airline          | domesticity                     |
      | Midwest Aviation | Domestic Data, US Carriers Only |

  Scenario Outline: Domesticity committee from airline for international airlines
    Given a flight emitter
    And a characteristic "airline.name" of "<airline>"
    When the "domesticity" committee is calculated
    Then the conclusion of the committee should be nil
    Examples:
      | airline          |
      | Aeroflot         |
      | United Airlines  |

  Scenario Outline: Domesticity committee from destination airport for domestic airports
    Given a flight emitter
    And a characteristic "destination_airport.iata_code" of "<iata_code>"
    When the "domesticity" committee is calculated
    Then the committee should have used quorum "from destination"
    And the conclusion of the committee should have a record with "name" equal to "<domesticity>"
    Examples:
      | iata_code | domesticity                     |
      | ALO       | Domestic Data, US Carriers Only |
      | TXK       | Domestic Data, US Carriers Only |

  Scenario Outline: Domesticity committee from destination airport for international airports
    Given a flight emitter
    And a characteristic "destination_airport.iata_code" of "<iata_code>"
    When the "domesticity" committee is calculated
    Then the conclusion of the committee should be nil
    Examples:
      | iata_code        |
      | DTW              |
      | IAD              |
      | GRR              |

  Scenario Outline: Domesticity committee from origin airport for domestic airports
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<iata_code>"
    When the "domesticity" committee is calculated
    Then the committee should have used quorum "from origin"
    And the conclusion of the committee should have a record with "name" equal to "<domesticity>"
    Examples:
      | iata_code | domesticity                     |
      | ALO       | Domestic Data, US Carriers Only |
      | TXK       | Domestic Data, US Carriers Only |

  Scenario Outline: Domesticity committee from destination for international airports
    Given a flight emitter
    And a characteristic "destination_airport.iata_code" of "<iata_code>"
    When the "domesticity" committee is calculated
    Then the conclusion of the committee should be nil
    Examples:
      | iata_code        |
      | DTW              |
      | IAD              |
      | GRR              |

  Scenario Outline: Domesticity committee from airports for domestic route
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<destination>"
    When the "domesticity" committee is calculated
    Then the committee should have used quorum "from origin"
    And the conclusion of the committee should have a record with "name" equal to "<domesticity>"
    Examples:
      | origin | destination | domesticity                     |
      | DTW    | SFO         | Domestic Data, US Carriers Only |

  Scenario Outline: Domesticity committee from airports for international route
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "<origin>"
    And a characteristic "destination_airport.iata_code" of "<destination>"
    When the "domesticity" committee is calculated
    Then the conclusion of the committee should be nil
    Examples:
      | origin | destination |
      | DTW    | CDG         |

  Scenario: Trips committee
    Given a flight emitter
    When the "trips" committee is calculated
    Then the conclusion of the committee should be "1.941"

  @pending
  Scenario: Freight share committee from cohort
    Given a flight emitter
    And a characteristic "origin_airport.iata_code" of "DTW"
    When the "freight_share" committee is calculated
    Then the committee should have used quorum "from cohort"
    And the conclusion of the committee should be "23"

  Scenario: Fuel type committee from default
    Given a flight emitter
    When the "fuel_type" committee is calculated
    Then the conclusion of the committee should have a record with "emission_factor" equal to "2.527139"
