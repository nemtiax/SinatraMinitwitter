class AddTweetIndex < ActiveRecord::Migration
  def up
	add_index(:tweets,:created_at)
  end
  
  def down
    remove_index(:tweets,:created_at)
  end
      
end
