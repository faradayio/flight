Feature: Flight Emissions Calculations
  The flight model should generate correct emission calculations

  Scenario Outline: Standard Calculations for origin/destination airport, airline, and craft
    Given a flight has "origin_airport.iata_code" of "<source>"
    And it has "destination_airport.iata_code" of "<dest>"
    And it has "airline.iata_code" of "<airline>"
    And it has "date" of "<date>"
    And it used "aircraft.icao_code" "<aircraft>"
    When emissions are calculated
    Then the emission value should be within 10 kgs of <emission>
    Examples:
      | source | dest | airline | date       | aircraft | emission |
      | DTW    | SFO  | UA      | 2010-06-25 | A320     | 1153     |
      | IAD    | CDG  | AF      | 2010-06-25 | A320     | 2070     |
