
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/static_assets'
require './config/environments' #database configuration

require './models/model'
 
get '/' do
    @tweets = get_recent_tweets(10)
	erb :login
end

put '/login' do
		@user = User.authenticate(params[:name], params[:pass])
		if(@user == nil)
			redirect_to login_url
		else 
			session[:user_id] = @user.id
			session[:user_name] = @user.name
			redirect_to home_url
		end
end


####HELPERS#######


	

    def get_followed_tweets(user, num_results)
		user.followed_tweets.order(:created_at).reverse.first(num_results)
	end
	
	def get_users_tweets(user,num_results)
		user.tweets.order(:created_at).reverse.first(num_results)
	end
	
	def get_recent_tweets(num_results)
		Tweet.all.order(:created_at).reverse.first(num_results)
	end