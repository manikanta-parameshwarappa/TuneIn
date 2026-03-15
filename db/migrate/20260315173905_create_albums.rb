class CreateAlbums < ActiveRecord::Migration[8.0]
  def change
    create_table :albums do |t|
      t.string :name
      t.date :released_date
      t.text :description
      t.references :artist, null: false, foreign_key: true

      t.timestamps
    end
  end
end
