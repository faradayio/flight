require 'sniff/database'

Sniff::Database.define_schema do
  create_table "flight_records", :force => true do |t|
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "distance_estimate"
    t.integer  "seats_estimate"
    t.float    "load_factor"
    t.time     "time_of_day"
    t.integer  "year"
    t.integer  "emplanements_per_trip"
    t.integer  "trips"
    t.string   "origin_airport_id"
    t.string   "destination_airport_id"
    t.string   "distance_class_id"
    t.string   "aircraft_id"
    t.string   "aircraft_class_id"
    t.string   "propulsion_id"
    t.string   "fuel_type_id"
    t.string   "airline_id"
    t.string   "seat_class_id"
    t.string   "domesticity_id"
  end
end
