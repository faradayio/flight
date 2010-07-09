Feature: Flight Committee Calculations
  The flight model should generate correct committee calculations

  Scenario Outline: Standard Calculations for origin/destination airport, airline, and craft
    Given a flight has "origin_airport.iata_code" of "<source>"
    And it has "destination_airport.iata_code" of "<dest>"
    And it has "airline.iata_code" of "<airline>"
    And it has "date" of "<date>"
    And it used "aircraft.icao_code" "<aircraft>"
    When emissions are calculated
    Then the fuel_per_segment committee should be close to <fuel_per_segment>, +/-10
    And the emplanements_per_trip committee should be exactly <emplanements_per_trip>
    And the fuel_use_coefficients committee should be exactly <fuel_use_coefficients>
    And the passengers committee should be exactly <passengers>
    Examples:
      | source | dest | airline | date       | aircraft | fuel | fuel_per_segment | adjusted_distance_per_segment | load_factor | passengers | adjusted_distance |
      | DTW    | SFO  | UA      | 2010-06-25 | A320     | 0    | 35127            | 1.67                          | 0           | 114        | 0                 |
      | IAD    | CDG  | AF      | 2010-06-25 | A320     | 0    | 53890            | 1.67                          | 0           | 114        | 0                 |
