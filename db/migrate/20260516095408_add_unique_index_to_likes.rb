class AddUniqueIndexToLikes < ActiveRecord::Migration[8.0]
  def change
    # Prevent duplicate likes: one user can only like a song once
    add_index :likes, [:user_id, :song_id], unique: true, name: "index_likes_on_user_id_and_song_id_unique"
  end
end
