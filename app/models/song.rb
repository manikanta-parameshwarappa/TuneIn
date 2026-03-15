class Song < ApplicationRecord
  belongs_to :album
  
  has_many :song_artists, dependent: :destroy
  has_many :artists, through: :song_artists
  has_many :playlist_songs, dependent: :destroy
  has_many :playlists, through: :playlist_songs
  has_many :likes, dependent: :destroy
  has_many :liked_users, through: :likes, source: :user

  has_one_attached :audio_file
end
