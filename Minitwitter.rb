
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/static_assets'
require './config/environments' #database configuration

require './models/model'

enable :sessions

ActiveRecord::Base.logger = Logger.new(STDOUT)


before do
	uri = URI.parse(ENV["REDISTOGO_URL"])
	REDIS ||= Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

get '/' do
    @tweets = get_recent_tweets(100)
	
	
	
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

post '/follow/:id' do
	if(session[:user_id]== nil) 
		redirect '/'
	else 
		@follower = User.find(session[:user_id])
		@followee = User.find(params[:id])
		FollowerConnection.create(follower: @follower, followee: @followee)
		redirect back
	end
end

get '/register' do
	erb :register
end

post '/register' do
	@user = User.new(name: params[:user_name],email: params[:user_email],password: params[:user_password], image_url: params[:user_image_url])
	@user.save
	redirect '/'
end

get '/tweets' do
	@tweets = get_recent_tweets(10)
	erb :firehose
end

get '/logout' do
	session.delete :user_id
	session.delete :user_name
	redirect '/'
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
		user.followed_tweets.order(:created_at).limit(num_results)
	end
	
	def get_users_tweets(user,num_results)
		user.tweets.order(:created_at).last(num_results)
	end
	
	def get_recent_tweets(num_results)
		
		if(not REDIS.exists("firehose"))
			recentTweets = Tweet.includes(:poster).all.order(created_at: :desc).limit(num_results)
			recentTweets.each do |tweet|
				#puts "STORED: #{tweet.to_json}"
				REDIS.rpush("firehose",tweet.to_json)
				REDIS.set("USER_#{tweet.user_id}",tweet.poster.to_json)
			end
		end
		tweets = REDIS.lrange("firehose",0,100)
		result = []
		tweets.each do |tweet|
			#puts "FETCHED: #{tweet}"
			result << Tweet.new.from_json(tweet)
		end
		return result
		
		#@@recentTweets ||= Tweet.includes(:poster).all.order(created_at: :desc).limit(num_results)
		
	end