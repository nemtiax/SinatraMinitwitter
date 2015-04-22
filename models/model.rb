require 'sinatra/extension'
require 'erb'
require 'ostruct'

class Tweet < ActiveRecord::Base
	belongs_to :poster, class_name: "User", foreign_key: "user_id"
	
	def cached_poster(redis)
	
		#tStart = Time.now
		#puts "CHECKING CACHE FOR USER_#{user_id}"
		if(redis.exists("USER_#{user_id}"))
			#puts "EXISTS!"
			#puts "END GET USER #{Time.now-tStart}"
			return User.new.from_json(redis.get("USER_#{user_id}"))
		else
			#puts "DOES NOT EXIST!"
			#puts "END GET USER #{Time.now-tStart}"
			return poster
		end
	end
	
		
	def propogate_to_followers(redis)
		followers = self.poster.followers
		followers.each do |follower|
			follower.add_to_feed(self,redis)
		end
	end
	
	
end

class FollowerConnection < ActiveRecord::Base
	belongs_to :follower, :class_name => :User
	belongs_to :followee, :class_name => :User
	validates_uniqueness_of :followee, :scope => [:follower]
end


class User < ActiveRecord::Base
	has_many :tweets
	has_many :follower_connections, :foreign_key => :follower_id, :dependent => :destroy
	has_many :followees, :class_name => "User", :through => :follower_connections, :source => :followee
	has_many :followed_tweets, :class_name => "Tweet", :through => :followees, :source => :tweets
	has_many :reverse_follower_connections, :class_name => "FollowerConnection", :foreign_key => :followee_id, :dependent => :destroy
	has_many :followers, :class_name => "User", :through => :reverse_follower_connections, :source => :follower
	
	
	
	
 # VIRTUAL ATTRIBUTES
  def password
   nil
  end

  def password=(my_password)
	self.hashed_password = AuthenticationHelper.hashPassword(my_password)
  end
  
  def self.authenticate(auth_name, auth_password) 
	AuthenticationHelper.new(auth_name).authenticate(auth_password)
  end
  
  def add_to_feed(tweet,redis)
	if(not redis.exists("#{self.id}_feed"))
		self.generate_feed(redis)
	else
		redis.rpop("#{self.id}_feed")
		redis.lpush("#{self.id}_feed", ErbHelper.tweet_render(tweet))
	end
  end
  
  def generate_feed(redis)
	followed_tweets = self.followed_tweets.includes(:poster).order(created_at: :desc).limit(100)
	followed_tweets.each do |tweet|
		redis.rpush("#{self.id}_feed",ErbHelper.tweet_render(tweet))
	end
  end
  	
end

class AuthenticationHelper

	def initialize (name)
		@name = name
	end

	def self.hashPassword(my_password) 
		Digest::MD5.hexdigest(my_password)
	end
	
	def authenticate(auth_password)
		User.where(name: @name, hashed_password: AuthenticationHelper.hashPassword(auth_password)).first
	end

end

module ErbHelper
 
 def self.tweet_render(tweet)
	 ERB.new(File.new("views/cached_tweet_display.erb").read).result(OpenStruct.new({:tweet => tweet}).instance_eval { binding })
 end
 
end

