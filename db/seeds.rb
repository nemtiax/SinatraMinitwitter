require 'set'


def escape(s)
	s.gsub(/'/,"_")
end


User.destroy_all

f = File.open("db/users.csv", "r")

userMap = Hash.new



f.each_line do |line|
		items = line.chomp.split(",")
		
		id = items[0]
		name = items[1]
		
		#userMap[id] = name
		
		User.create({name: name,email: "#{escape(name)}@example.com", image_url: 'default.png', password: 'password'})
		userMap[id] = User.where(name: name).take
		
		puts "Created #{name}"
end

puts "Starting follows"
f = File.open("db/follows.csv","r")


FollowerConnection.destroy_all

followSet = Set.new

count = 0
f.each_line do |line|
	if(not followSet.include?(line))
		followSet.add(line)
		items = line.chomp.split(",")
		follower = items[0]
		followee = items[1]
		FollowerConnection.create(follower: userMap[follower], followee: userMap[followee])
		count = count + 1
		if(count%1000 == 0) 
			puts "#{count} follows created\n"
		end
	end
end


puts "Starting tweets"

f = File.open("db/tweets.csv", "r")


Tweet.destroy_all

count = 0

f.each_line do |line|
		result = /^(\d+),"(.+)",(.*)$/.match(line)
		id = result[1]
		tweet = result[2]
		date = result[3]
		count = count + 1
		if(count%1000 == 0) 
			puts "#{count} tweets posted\n"
		end
		
		Tweet.create({body: "#{tweet}",poster: userMap[id],created_at: Time.parse(date).to_datetime})
end

