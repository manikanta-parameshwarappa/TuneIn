class User < ApplicationRecord
  has_one :artist, dependent: :destroy
  has_many :playlists, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_songs, through: :likes, source: :song

  has_one_attached :avatar

  enum role: { listener: 0, artist: 1, admin: 2 }
end
