class PlaylistsController < ApplicationController
  include Authenticatable
  before_action :set_playlist, only: [:show, :update, :destroy]

  # GET /playlists
  def index
    playlists = current_user.playlists.includes(songs: [:album, :artists])
    render json: playlists.map { |p| playlist_json(p) }
  end

  # GET /playlists/:id
  def show
    render json: playlist_json(@playlist)
  end

  # POST /playlists
  def create
    playlist = current_user.playlists.build(playlist_params)

    if playlist.save
      render json: playlist_json(playlist), status: :created
    else
      render json: { errors: playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /playlists/:id
  def update
    if @playlist.update(playlist_params)
      render json: playlist_json(@playlist)
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /playlists/:id
  def destroy
    @playlist.destroy
    render json: { message: "Playlist deleted successfully" }
  end

  private

  def set_playlist
    @playlist = current_user.playlists.find_by(id: params[:id])
    render json: { error: "Playlist not found" }, status: :not_found unless @playlist
  end

  def playlist_params
    params.require(:playlist).permit(:name, :description, :is_public)
  end

  def playlist_json(playlist)
    playlist.as_json(only: [:id, :name, :description, :is_public, :created_at, :updated_at]).tap do |p|
      p["song_count"] = playlist.songs.count
      p["songs"] = playlist.songs.includes(:album, :artists).map { |song|
        song.as_json(only: [:id, :name, :duration, :genre, :album_id]).tap do |s|
          album = song.album
          s["album"] = album ? album.as_json(only: [:id, :name]).merge(
            "cover_image_url" => album.cover_image.attached? ? rails_blob_url(album.cover_image, only_path: true) : nil
          ) : nil
          s["artists"] = song.artists.map { |a|
            a.as_json(only: [:id, :bio]).merge("user" => a.user.as_json(only: [:id, :name, :email]))
          }
          s["audio_url"] = song.audio_file.attached? ? rails_blob_url(song.audio_file, only_path: true) : nil
        end
      }
    end
  end
end
