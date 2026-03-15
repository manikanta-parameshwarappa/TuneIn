class RemovePositionFromPlaylistSongs < ActiveRecord::Migration[8.0]
  def change
    remove_column :playlist_songs, :position, :integer
  end
end
