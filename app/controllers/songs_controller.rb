class SongsController < ApplicationController
  include Authenticatable

  before_action :authorize_admin!, only: [:create, :update, :destroy]
  before_action :set_song, only: [:show, :update, :destroy]

  # GET /songs
  def index
    songs = Song.includes(:album, :artists).all
    render json: songs, include: [:album, :artists]
  end

  # POST /songs/bulk_create
  def bulk_create
    created_songs = []

    params[:songs].each do |_, song_data|
      # song_data is now the ActionController::Parameters object
      permitted = song_data.permit(:file, :name, :duration, :genre, :album_id, artist_ids: []).to_h.symbolize_keys

      album = Album.find(permitted[:album_id])

      song = album.songs.build(
        name: permitted[:name],
        duration: permitted[:duration],
        genre: permitted[:genre]
      )

      if song.save
        # Link artists if provided
        if permitted[:artist_ids].present?
          song.song_artists.destroy_all
          permitted[:artist_ids].each do |artist_id|
            song.song_artists.create(artist_id: artist_id)
          end
        end

        # Attach audio file if provided
        if permitted[:file].present?
          song.audio_file.attach(permitted[:file])
        end

        created_songs << song
      else
        return render json: { errors: song.errors.full_messages }, status: :unprocessable_entity
      end
    end

    render json: created_songs, include: [:album, :artists], status: :created
  end

  # GET /songs/:id
  def show
    render json: @song, include: [:album, :artists]
  end

  # POST /songs
  def create
    album =
      if current_user.role == "artist"
        current_user.artist.albums.find(params[:album_id])
      elsif current_user.role == "admin"
        Album.find(params[:album_id])
      else
        return render json: { error: "Forbidden" }, status: :forbidden
      end

    song = album.songs.build(song_params)

    if song.save
      attach_artists(song)
      attach_audio(song)
      render json: song, include: [:album, :artists], status: :created
    else
      render json: { errors: song.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /songs/:id
  def update
    if @song.update(song_params)
      attach_artists(@song)
      attach_audio(@song)
      render json: @song, include: [:album, :artists]
    else
      render json: { errors: @song.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /songs/:id
  def destroy
    @song.destroy
    render json: { message: "Song deleted successfully" }
  end

  private

  def set_song
    @song = Song.find_by(id: params[:id])
    render json: { error: "Song not found" }, status: :not_found unless @song
  end

  def song_params
    params.require(:song).permit(:name, :duration, :genre)
  end

  def attach_artists(song)
    return unless params[:artist_ids].present?

    song.song_artists.destroy_all
    params[:artist_ids].each do |artist_id|
      song.song_artists.create(artist_id: artist_id)
    end
  end

  def attach_audio(song)
    return unless params[:audio_file].present?

    song.audio_file.attach(params[:audio_file])
  end
end
