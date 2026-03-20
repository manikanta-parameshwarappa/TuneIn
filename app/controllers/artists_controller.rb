class ArtistsController < ApplicationController
  include Authenticatable

  before_action :authorize_admin!, only: [:create, :update, :destroy]
  before_action :set_artist, only: [:show, :update, :destroy]

  # GET /artists
  def index
    artists = Artist.includes(:user).all
    render json: {
      artists: artists.map { |artist|
        {
          id: artist.id,
          name: artist.user.name,
          bio: artist.bio,
          email: artist.user.email
        }
      },
      count: artists.size
    }
  end

  # GET /artists/:id
  def show
    render json: {
      id: @artist.id,
      name: @artist.user.name,
      bio: @artist.bio,
      user: {
        id: @artist.user.id,
        email: @artist.user.email,
        role: @artist.user.role
      }
    }
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
      render json: {
        id: artist.id,
        name: user.name,
        bio: artist.bio,
        user: {
          id: user.id,
          email: user.email,
          role: user.role
        },
        created_at: artist.created_at,
        updated_at: artist.updated_at
      }, status: :created
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
