module BrighterPlanet
  module Flight
    module Summarization
      def self.included(base)
        base.summarize do |has|
          has.adjective 'one-way', :if => lambda { |flight| flight.trips == 1 }
          has.adjective 'round-trip', :if => lambda { |flight| flight.trips == 1 }
          has.adjective 'nonstop', :if => lambda { |flight| flight.emplanements_per_trip == 1 }
          has.identity 'flight'
          has.modifier lambda { |flight| "from #{flight.origin_airport.name}" }, :if => :origin_airport
          has.modifier lambda { |flight| "to #{flight.destination_airport.name}" }, :if => :destination_airport
          has.modifier lambda { |flight| "on a #{flight.vehicle}" }, :if => :vehicle
          has.modifier lambda { |flight| "on #{flight.date.to_formatted_s(:archive)}"}, :if => :date
          has.verb :take
          has.aspect :perfect
        end
      end
    end
  end
end
