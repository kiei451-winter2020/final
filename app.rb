# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"
require "sinatra/cookies"                                                             #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "bcrypt"                                                                      #
require "twilio-ruby"                                                                 #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

courses_table = DB.from(:courses)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)


before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

# homepage and list of courses (aka "index")
get "/" do
    puts "params: #{params}"

    @courses = courses_table.all.to_a
    pp @courses

    view "courses"
end

# course details (aka "show")
get "/courses/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @courses = courses_table.where(id: params[:id]).to_a[0]
    pp @courses

    @reviews = reviews_table.where(course_id: @courses[:id]).to_a
    @going_count = reviews_table.where(course_id: @courses[:id], going: true).count

    view "courses"
end

# display the review form (aka "new")
get "/courses/:id/reviews/new" do
    puts "params: #{params}"

    @course = courses_table.where(id: params[:id]).to_a[0]
    view "new_course"
end

# receive the submitted review form (aka "create")
post "/courses/:id/reviews/create" do
    puts "params: #{params}"

    # first find the course that review'ing for
    @course = courses_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the reviews table with the review form data

        #RA NOTE - FIX THIS TO ALIGN WITH DOMAIN MODEL
        
    # reviews_table.insert(
    #     course_id: @course[:id],
    #     user_id: session["user_id"],
    #     comments: params["comments"],
    #     going: params["going"]
    # )

    redirect "/courses/#{@course[:id]}"
end

# display the review form (aka "edit")
get "/reviews/:id/edit" do
    puts "params: #{params}"

    @review = reviews_table.where(id: params["id"]).to_a[0]
    @course = courses_table.where(id: @review[:course_id]).to_a[0]
    view "edit_review"
end

# receive the submitted review form (aka "update")
post "/reviews/:id/update" do
    puts "params: #{params}"

    # find the review to update
    @review = reviews_table.where(id: params["id"]).to_a[0]
    # find the review's course
    @course = courses_table.where(id: @review[:course_id]).to_a[0]

    if @current_user && @current_user[:id] == @review[:id]
        reviews_table.where(id: params["id"]).update(
            going: params["going"],
            comments: params["comments"]
        )

        redirect "/courses/#{@course[:id]}"
    else
        view "error"
    end
end

# delete the review (aka "destroy")
get "/reviews/:id/destroy" do
    puts "params: #{params}"

    review = reviews_table.where(id: params["id"]).to_a[0]
    @course = courses_table.where(id: review[:course_id]).to_a[0]

    reviews_table.where(id: params["id"]).delete

    redirect "/courses/#{@course[:id]}"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end