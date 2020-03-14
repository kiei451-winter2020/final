# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
require "geocoder"  
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

houses_table = DB.from(:houses)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do
    puts houses_table.all
    @houses = houses_table.all
    view "houses"
end

get "/houses/:id" do
    @house = houses_table.where(id: params[:id]).first
    @candy_avg = reviews_table.where(house_id: @house[:id]).avg(:candy)
    @decorations_avg = reviews_table.where(house_id: @house[:id]).avg(:decorations)
    @recommend_count = reviews_table.where(house_id: @house[:id], recommend: true).count
    @not_recommend_count = reviews_table.where(house_id: @house[:id], recommend: false).count
    view "house"
end

get "/houses/:id/reviews/new" do
    @house = houses_table.where(id: params[:id]).first
    view "new_review"
end

get '/houses/:id/reviews/create' do
  puts params
  @house = houses_table.where(id: params[:id]).to_a[0]
  reviews_table.insert(house_id: params["id"],
                       recommend: params["recommend"],
                       candy: params["candy"],
                       decorations: params["decorations"],
                       name: params["name"])
  view "create_review"
end

get "/nocandy" do
    view "no_candy"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts params
    hashed_password = BCrypt::Password.create(params["password"])
    users_table.insert(name: params["name"], email: params["email"], password: hashed_password)
    view "create_user"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    user = users_table.where(email: params["email"]).to_a[0]
    puts BCrypt::Password::new(user[:password])
    if user && BCrypt::Password::new(user[:password]) == params["password"]
        session["user_id"] = user[:id]
        @current_user = user
        view "create_login"
    else
        view "create_login_failed"
    end
end

get "/logout" do
    session["user_id"] = nil
    @current_user = nil
    view "logout"
end