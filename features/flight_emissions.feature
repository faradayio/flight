Feature: Flight Emissions Calculations
  The flight model should generate correct emission calculations

  Scenario Outline: Standard Calculations
    Given a flight has origin_airport.iata_code of <source>
    And it has destination_airport.iata_code of <dest>
    And it has airline of <airline>
    When emissions are calculated
    Then the emission value should be within 10 kgs of <emission>
    And the fuel_per_segment committee should be close to <fuel_per_segment>, +/-10
    And the emplanements_per_trip committee should be exactly <emplanements_per_trip>
    And the fuel_use_coefficients committee should be exactly <fuel_use_coefficients>
    And the passengers committee should be exactly <passengers>
    Examples:
      each committee has its own column - if nil, don't check emission for that committee
      | source | dest | airline | emission | fuel_per_segment | emplanements_per_trip | fuel_use_coefficients | passengers |
      | DTW    | SFO  | UA      | 6102     | 35127            | 1.67                  | 0 m3, 7 m1, 0 m2      | 114        |
      | IAD    | CDG  | AF      | 9362     | 53890            | 1.67                  | 0 m3, 7 m1, 0 m2      | 114        |
