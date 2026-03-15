class ArtistsController < ApplicationController
  before_action :authorize_request
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
    # Only admins can create artist users
    unless current_user.role == "admin"
      return render json: { error: "Forbidden" }, status: :forbidden
    end

    user = User.new(
      name: params[:name],
      email: params[:email],
      password: params[:password],
      password_confirmation: params[:password_confirmation],
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

  def set_artist
    @artist = Artist.find_by(id: params[:id])
    render json: { error: "Artist not found" }, status: :not_found unless @artist
  end

  def artist_params
    params.permit(:bio)
  end
end
