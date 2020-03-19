# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :courses do
  primary_key :id
  String :title
  String :location
end
DB.create_table! :reviews do
  primary_key :id
  foreign_key :course_id
  foreign_key :user_id
  integer :rating
  String :date
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  Integer :handicap
  String :email
  String :password
end

# Insert initial (seed) data
courses_table = DB.from(:courses)

courses_table.insert(title: "Wilmette Golf Club", 
                    location: "Wilmette, IL")

courses_table.insert(title: "Sunset Valley", 
                    location: "Highland Park, IL")


courses_table.insert(title: "Harborside", 
                    location: "Chicago, IL")
