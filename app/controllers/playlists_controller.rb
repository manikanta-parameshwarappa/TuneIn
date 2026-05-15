class PlaylistsController < ApplicationController
  include Authenticatable
  before_action :set_playlist, only: [:show, :update, :destroy, :add_song, :remove_song]

  # GET /playlists
  def index
    playlists = current_user.playlists.includes(:songs)
    render json: playlists, include: :songs
  end

  # GET /playlists/:id
  def show
    render json: @playlist, include: :songs
  end

  # POST /playlists
  def create
    playlist = current_user.playlists.build(playlist_params)

    if playlist.save
      render json: playlist, status: :created
    else
      render json: { errors: playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /playlists/:id
  def update
    if @playlist.update(playlist_params)
      render json: @playlist
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /playlists/:id
  def destroy
    @playlist.destroy
    render json: { message: "Playlist deleted successfully" }
  end

  # POST /playlists/:id/add_song
  def add_song
    song = Song.find(params[:song_id])
    @playlist.playlist_songs.create(song: song)
    render json: @playlist, include: :songs
  end

  # DELETE /playlists/:id/remove_song
  def remove_song
    playlist_song = @playlist.playlist_songs.find_by(song_id: params[:song_id])
    if playlist_song
      playlist_song.destroy
      render json: @playlist, include: :songs
    else
      render json: { error: "Song not found in playlist" }, status: :not_found
    end
  end

  private

  def set_playlist
    @playlist = current_user.playlists.find_by(id: params[:id])
    render json: { error: "Playlist not found" }, status: :not_found unless @playlist
  end

  def playlist_params
    params.require(:playlist).permit(:name, :description, :is_public)
  end
end
