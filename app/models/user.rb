class User < ApplicationRecord
  ROLES = %w[listener artist admin].freeze
  validates :role, inclusion: { in: ROLES }

  has_one :artist, dependent: :destroy
  has_many :playlists, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_songs, through: :likes, source: :song

  has_one_attached :avatar
end
