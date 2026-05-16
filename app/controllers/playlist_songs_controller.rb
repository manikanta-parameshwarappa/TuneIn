class PlaylistSongsController < ApplicationController
  include Authenticatable
  before_action :set_playlist

  # POST /playlists/:playlist_id/playlist_songs
  # body: { playlist_song: { song_id: <id> } }
  def create
    song_id = params.dig(:playlist_song, :song_id) || params[:song_id]
    song = Song.find_by(id: song_id)
    return render json: { error: "Song not found" }, status: :not_found unless song

    # Prevent duplicates
    if @playlist.playlist_songs.exists?(song_id: song.id)
      return render json: { error: "Song already in playlist" }, status: :unprocessable_entity
    end

    playlist_song = @playlist.playlist_songs.create(song: song)

    if playlist_song.persisted?
      render json: playlist_json(@playlist), status: :created
    else
      render json: { errors: playlist_song.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /playlists/:playlist_id/playlist_songs/:id
  # :id here is the song_id (we accept both song_id and playlist_song id)
  def destroy
    # Try to find by playlist_song id first, then by song_id
    playlist_song = @playlist.playlist_songs.find_by(id: params[:id]) ||
                    @playlist.playlist_songs.find_by(song_id: params[:id])

    if playlist_song
      playlist_song.destroy
      render json: playlist_json(@playlist)
    else
      render json: { error: "Song not found in playlist" }, status: :not_found
    end
  end

  private

  def set_playlist
    @playlist = current_user.playlists.find_by(id: params[:playlist_id])
    render json: { error: "Playlist not found" }, status: :not_found unless @playlist
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