class Tweet < ActiveRecord::Base
	belongs_to :poster, class_name: "User", foreign_key: "user_id"
end
