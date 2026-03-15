class CreateSongs < ActiveRecord::Migration[8.0]
  def change
    create_table :songs do |t|
      t.string :name
      t.references :album, null: false, foreign_key: true
      t.integer :duration
      t.string :genre

      t.timestamps
    end
  end
end
