class Album < ApplicationRecord
  belongs_to :artist
  has_many :songs, dependent: :destroy

  has_one_attached :cover_image
end
