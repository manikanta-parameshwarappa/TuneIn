class CreatePlaylists < ActiveRecord::Migration[8.0]
  def change
    create_table :playlists do |t|
      t.string :name
      t.string :description
      t.references :user, null: false, foreign_key: true
      t.boolean :is_public

      t.timestamps
    end
  end
end
