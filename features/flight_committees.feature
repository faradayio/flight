Feature: Flight Committee Calculations
  The flight model should generate correct committee calculations

  Scenario Outline: Standard Calculations for origin/destination airport, airline, and craft
    Given a flight has "origin_airport.iata_code" of "<source>"
    And it has "destination_airport.iata_code" of "<dest>"
    And it has "airline.iata_code" of "<airline>"
    And it has "date" of "<date>"
    And it used "aircraft.icao_code" "<aircraft>"
    When emissions are calculated
    Then the fuel committee should be close to <fuel>, +/-1
    And the fuel_per_segment committee should be close to <fuel_per_segment>, +/-10
    And the adjusted_distance_per_segment committee should be close to <adjusted_distance_per_segment>, +/-1
    And the load_factor committee should be close to <load_factor>, +/-0.001
    And the passengers committee should be exactly <passengers>
    And the adjusted_distance committee should be close to <adjusted_distance>, +/-1
    Examples:
      | source | dest | airline | date       | aircraft | fuel  | fuel_per_segment | adjusted_distance_per_segment | load_factor | passengers | adjusted_distance |
      | DTW    | SFO  | UA      | 2010-06-25 | A320     | 24676 | 7612             | 1341                          | 0.801       | 120        | 2241              |
      | IAD    | CDG  | AF      | 2010-06-25 | A320     | 43477 | 13413            | 2492                          | 0.800       | 120        | 4161              |
