
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/static_assets'
require './config/environments' #database configuration

require './models/model'

enable :sessions


get '/' do
    @tweets = get_recent_tweets(10)
	erb :login
end

post '/login' do
		@user = User.authenticate(params[:name], params[:pass])
		if(@user == nil)
			redirect '/'
		else 
			session[:user_id] = @user.id
			session[:user_name] = @user.name
			redirect '/home'
		end
end

get '/home' do
	if(session[:user_id]== nil) 
		redirect '/'
	else 
		@user = User.find(session[:user_id])
		@followed_tweets = get_followed_tweets(@user,10)
		erb :home
	end
end

post '/tweet' do
	@tweet = Tweet.new(user_id: session[:user_id], body: params[:tweet_text])
	@tweet.save
	redirect '/home'
end

get '/users/:id_or_name' do
	get_user(params[:id_or_name])
	if(@user == nil) 
		redirect '/'
	end
	@tweets = get_users_tweets(@user,10)
	@followees = @user.followees
	erb :user
end

####HELPERS#######


	

	def get_user(id_or_name)
		begin
			@user = User.find(id_or_name)
		rescue ActiveRecord::RecordNotFound
			@user = User.where(name: id_or_name).first
		end
	end
	
    def get_followed_tweets(user, num_results)
		user.followed_tweets.order(:created_at).reverse.first(num_results)
	end
	
	def get_users_tweets(user,num_results)
		user.tweets.order(:created_at).reverse.first(num_results)
	end
	
	def get_recent_tweets(num_results)
		Tweet.all.order(:created_at).reverse.first(num_results)
	end