class AlbumsController < ApplicationController
   # GET /albums
  def index
    albums = Album.all
    render json: albums
  end

  # GET /albums/:id
  def show
    album = Album.find(params[:id])
    render json: album, include: :songs
  end

  # POST /albums
  def create
    album = Album.new(album_params)
    if album.save
      render json: album, status: :created
    else
      render json: album.errors, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /albums/:id
  def update
    album = Album.find(params[:id])
    if album.update(album_params)
      render json: album
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

  def album_params
    params.require(:album).permit(:name, :released_date, :description, :artist_id, :cover_image)
  end
end
