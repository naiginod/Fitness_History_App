require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'yaml'

configure do
  enable :sessions
  set :session_secret, "super secret"
end

before do
  session[:date] ||= {}
end

def exercise_data
  data = File.expand_path("../exercises.yaml", __FILE__)
  YAML.load_file(data)
end

def load_user_credentials
  users = File.expand_path("../users.yaml", __FILE__)
  YAML.load_file(users)
end

def validate_credentials?(user, password)
  user_list = load_user_credentials
  user_list.keys.include?(user) && user_list[user] == password
end

def upper_body
  exercise_data["upper_body"]
end

def lower_body
  exercise_data["lower_body"]
end

def cardio
  exercise_data["cardio"]
end

get "/" do
  @upper = upper_body
  @lower = lower_body
  @cardio = cardio
  @users = load_user_credentials
  erb :main
end

post "/signin" do 
  session[:user] = params[:user]
  session[:password] = params[:password]
  redirect "/user"
end

get "/user" do
  if validate_credentials?(session[:user], session[:password])
    session[:accepted] = true
  else
    session[:message] = "Login credentials are invalid"
  end
  redirect "/"
end

get "/signout" do
  session[:accepted] = nil
  redirect "/"
end

post "/exercise-log" do
  d, m, y = params[:date].split("/")
  if !Date.valid_date?(y.to_i, m.to_i, d.to_i)
    session[:message] = "Invalid Date"
  elsif session[:date].keys.include?(params[:date])
    session[:date][params[:date]] << [params[:exercise], params[:amount]]
  else
    session[:date][params[:date]] = [[params[:exercise], params[:amount]]]
  end
  redirect "/exercise-log"
end

get "/exercise-log" do
  redirect "/" if session[:user].nil?

  @log = session[:date]
  erb :exercise
end
