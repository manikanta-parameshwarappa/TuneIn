class ArtistsController < ApplicationController
  include Authenticatable

  before_action :authorize_admin!, only: [:create, :update, :destroy]
  before_action :set_artist, only: [:show, :update, :destroy]

  # GET /artists
  def index
    render json: Artist.includes(:user).all, include: :user
  end

  # GET /artists/:id
  def show
    render json: @artist, include: :user
  end

  # POST /artists
  def create
    password = "secureartist123"
    user = User.new(
      name: params[:name],
      email: params[:email],
      password: password,
      password_confirmation: password,
      role: "artist"
    )

    if user.save
      artist = Artist.create(user: user, bio: params[:bio])
      render json: { user: user, artist: artist }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /artists/:id
  def update
    if @artist.update(artist_params)
      render json: @artist
    else
      render json: { errors: @artist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /artists/:id
  def destroy
    @artist.user.destroy
    render json: { message: "Artist user deleted successfully" }
  end

  private

  def authorize_admin!
    unless current_user&.role == "admin"
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end

  def set_artist
    @artist = Artist.find_by(id: params[:id])
    render json: { error: "Artist not found" }, status: :not_found unless @artist
  end

  def artist_params
    params.permit(:bio)
  end
end
