class Tweet < ActiveRecord::Base
	belongs_to :poster, class_name: "User", foreign_key: "user_id"
	
	def cached_poster
		if(defined? REDIS and REDIS.contains("USER_#{user_id}"))
			return User.new.from_json(REDIS.get("USER_#{user_id}"))
		else
			return poster
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


