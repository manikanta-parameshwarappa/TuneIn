class User < ApplicationRecord
  ROLES = %w[listener artist admin].freeze
  
  has_secure_password

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  validates :role, inclusion: { in: ROLES }

  has_one :artist, dependent: :destroy
  has_many :playlists, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_songs, through: :likes, source: :song

  has_one_attached :avatar
end
