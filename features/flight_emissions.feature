Feature: Flight Emissions Calculations
  The flight model should generate correct emission calculations

  Scenario Outline: Standard Calculations for origin/destination airport, airline, and aircraft
    Given a flight has "origin_airport.iata_code" of "<source>"
    And it has "destination_airport.iata_code" of "<dest>"
    And it has "airline.iata_code" of "<airline>"
    And it has "date" of "<date>"
    And it used "aircraft.bts_aircraft_type_code" "<aircraft>"
    When emissions are calculated
    Then the emission value should be within 1 kgs of <emission>
    Examples:
      | source | dest | airline | date       | aircraft | emission |
      | DCA    | JFK  | AA      | 2010-06-25 | 1        | 1153     |
