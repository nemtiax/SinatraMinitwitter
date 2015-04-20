
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/static_assets'
require './config/environments' #database configuration

require './models/model'
require 'delayed_job'

enable :sessions

ActiveRecord::Base.logger = Logger.new(STDOUT)



configure :production do
	uri = URI.parse(ENV["REDISTOGO_URL"])
	REDIS ||= Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
	Delayed::Worker.backend = :active_record
	Delayed::Worker.destroy_failed_jobs = true
	Delayed::Worker.sleep_delay = 5
	Delayed::Worker.max_attempts = 5
	Delayed::Worker.max_run_time = 5.minutes
end

get '/' do
    @cached_tweets = get_recent_tweets
	erb :login, :locals => {:cached_tweets => @cached_tweets}
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
		
		@followed_tweets = get_followed_tweets(session[:user_id])
		erb :home, :locals => {:cached_tweets => @followed_tweets}
	end
end

post '/tweet' do
	post_and_cache_tweet( session[:user_id],params[:tweet_text])
	redirect '/home'
end

get '/redis_reset' do
	REDIS.flushdb()
	redirect '/'
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


	def post_and_cache_tweet(user_id,tweet_text)
		tweet = Tweet.new(user_id: user_id, body: tweet_text)
		tweet.save
		if(not REDIS.exists("firehose"))
			generate_firehose
		end
		REDIS.rpoplpush("firehose", erb(:cached_tweet_display, :locals => {:tweet => tweet}))
		tweet.delay.propogate_to_followers
		
	end

	def get_user(id_or_name)
		begin
			@user = User.find(id_or_name)
		rescue ActiveRecord::RecordNotFound
			@user = User.where(name: id_or_name).first
		end
	end
	
    def get_followed_tweets(user_id)
		
		if(not REDIS.exists("#{user_id}_feed"))
			generate_user_feed(get_user(user_id))
		end
		return REDIS.lrange("#{user_id}_feed",0,100)
		
	end
	
	def get_users_tweets(user,num_results)
		user.tweets.order(:created_at).last(num_results)
	end
	
	def generate_firehose
			recentTweets = Tweet.includes(:poster).all.order(created_at: :desc).limit(100)
			recentTweets.each do |tweet|
				REDIS.rpush("firehose", erb(:cached_tweet_display, :locals => {:tweet => tweet}))
			end
	end
	
	def generate_user_feed(user)
		user.generate_feed(REDIS)
	end
	
	def get_recent_tweets
		if(not REDIS.exists("firehose"))
			generate_firehose
		end
		tweets = REDIS.lrange("firehose",0,100)
		return tweets
	end