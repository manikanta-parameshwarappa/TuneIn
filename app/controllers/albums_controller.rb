class AlbumsController < ApplicationController
  include Authenticatable

  before_action :authorize_admin!, only: [:create, :update, :destroy]

  # GET /albums
  def index
    albums = Album.includes(artist: :user).all
    render json: albums.map { |album| serialize_album(album) }
  end

  # GET /albums/:id
  def show
    album = Album.includes(:songs, artist: :user).find(params[:id])
    render json: serialize_album(album).merge(songs: album.songs)
  end

  # POST /albums
  def create
    album = Album.new(album_params)
    if album.save
      album = Album.includes(artist: :user).find(album.id)
      render json: serialize_album(album), status: :created
    else
      render json: album.errors, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /albums/:id
  def update
    album = Album.includes(artist: :user).find(params[:id])
    if album.update(album_params)
      render json: serialize_album(album)
    else
      render json: album.errors, status: :unprocessable_entity
    end
  end

  # DELETE /albums/:id
  def destroy
    album = Album.find(params[:id])
    album.destroy
    head :no_content
  end

  private

  def serialize_album(album)
    cover_url = album.cover_image.attached? \
      ? rails_blob_path(album.cover_image, only_path: true) \
      : nil

    {
      id: album.id,
      name: album.name,
      released_date: album.released_date,
      description: album.description,
      artist_id: album.artist_id,
      cover_image_url: cover_url,
      artist: album.artist ? {
        id: album.artist.id,
        name: album.artist.user&.name,
        email: album.artist.user&.email
      } : nil,
      created_at: album.created_at,
      updated_at: album.updated_at
    }
  end

  def authorize_admin!
    unless current_user&.role == "admin"
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end

  def album_params
    params.require(:album).permit(:name, :released_date, :description, :artist_id, :cover_image)
  end
end
