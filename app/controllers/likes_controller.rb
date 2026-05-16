class LikesController < ApplicationController
  include Authenticatable

  # POST /songs/:song_id/likes — toggle like (like if not liked, unlike if already liked)
  def create
    song = Song.find_by(id: params[:song_id])
    return render json: { error: "Song not found" }, status: :not_found unless song

    existing_like = current_user.likes.find_by(song_id: song.id)

    if existing_like
      # Unlike
      existing_like.destroy
      render json: { liked: false, song_id: song.id, likes_count: song.likes.count }
    else
      # Like
      like = current_user.likes.create(song: song)
      if like.persisted?
        render json: { liked: true, song_id: song.id, likes_count: song.likes.count }, status: :created
      else
        render json: { errors: like.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  # GET /songs/:song_id/likes — check if current user liked this song
  def index
    song = Song.find_by(id: params[:song_id])
    return render json: { error: "Song not found" }, status: :not_found unless song

    liked = current_user.likes.exists?(song_id: song.id)
    render json: { liked: liked, song_id: song.id, likes_count: song.likes.count }
  end

  # GET /users/:user_id/likes — fetch all liked songs for the current user
  # (user_id in path is ignored; always uses current_user for security)
  def user_likes
    liked_songs = current_user.liked_songs.includes(:album, :artists)
    render json: liked_songs.map { |song| song_json(song) }
  end

  private

  def song_json(song)
    song.as_json(only: [:id, :name, :duration, :genre, :album_id]).tap do |s|
      album = song.album
      s["album"] = album ? album.as_json(only: [:id, :name]).merge(
        "cover_image_url" => album.cover_image.attached? ? rails_blob_url(album.cover_image, only_path: true) : nil
      ) : nil
      s["artists"] = song.artists.map { |a|
        a.as_json(only: [:id, :bio]).merge("user" => a.user.as_json(only: [:id, :name, :email]))
      }
      s["audio_url"] = song.audio_file.attached? ? rails_blob_url(song.audio_file, only_path: true) : nil
      s["liked"] = true
    end
  end
end
