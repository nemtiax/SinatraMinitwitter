class AddTweetPosterIndex < ActiveRecord::Migration
  def up
	add_index(:tweets,:user_id)
  end
  
  def down
    remove_index(:tweets,:user_id)
  end
      
end
