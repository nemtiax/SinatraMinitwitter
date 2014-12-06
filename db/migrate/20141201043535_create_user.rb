class CreateUser < ActiveRecord::Migration
  def up
	create_table :users do |t|
      t.string :name
      t.string :email
      t.string :image_url
	  t.string :hashed_password

      t.timestamps
	end
	  
	create_table :tweets do |t|
      t.text :body
	  t.integer :user_id
	  
      t.timestamps
	end
	  
	create_table :follower_connections do |t|
      t.integer :follower_id
      t.integer :followee_id

      t.timestamps
    end
	  
  end
  
  def down
  
    drop_table :users
	drop_table :tweets
	drop_table :follower_connections
  end
      
end
