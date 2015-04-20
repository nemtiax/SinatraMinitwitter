class Tweet < ActiveRecord::Base
	belongs_to :poster, class_name: "User", foreign_key: "user_id"
	
	def propogate_to_followers(redis)
		followers = self.poster.followers
		puts followers
	end
	
end
