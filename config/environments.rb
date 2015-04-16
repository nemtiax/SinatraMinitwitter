configure :production, :development do
#postgres://{user}:{password}@{host}:{port}/path
	db = URI.parse(ENV['DATABASE_URL'] || 'postgres://rails:password@localhost/sinatra')
	
	ActiveRecord::Base.establish_connection(
			:adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
			:host     => db.host,
			:username => db.user,
			:password => db.password,
			:database => db.path[1..-1],
			:encoding => 'utf8'
	)
	
	require 'redis'
	uri = URI.parse(ENV["REDISTOGO_URL"])
	REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
	
	require 'newrelic_rpm'
	
end