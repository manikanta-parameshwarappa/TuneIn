class ArtistsController < ApplicationController
  include Authenticatable

  before_action :authorize_admin!, only: [:create, :update, :destroy]
  before_action :set_artist, only: [:show, :update, :destroy]

  # GET /artists
  def index
    artists = Artist.includes(:user).all
    render json: {
      artists: artists.map { |artist| serialize_artist(artist) },
      count: artists.size
    }
  end

  # GET /artists/:id
  def show
    render json: serialize_artist(@artist)
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

    user.avatar.attach(params[:avatar]) if params[:avatar].present?

    if user.save
      artist = Artist.new(user: user, bio: params[:bio])
      if artist.save
        render json: serialize_artist(artist), status: :created
      else
        user.destroy
        render json: { errors: artist.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /artists/:id
  def update
    user = @artist.user
    user_update_params = {}
    user_update_params[:name]   = params[:name]  if params[:name].present?
    user_update_params[:email]  = params[:email] if params[:email].present?
    user_update_params[:avatar] = params[:avatar] if params[:avatar].present?

    user_valid = user_update_params.empty? || user.update(user_update_params)

    if user_valid && @artist.update(artist_params)
      render json: serialize_artist(@artist)
    else
      errors = @artist.errors.full_messages + (user_valid ? [] : user.errors.full_messages)
      render json: { errors: errors }, status: :unprocessable_entity
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

  def avatar_url(user)
    return nil unless user.avatar.attached?

    Rails.application.routes.url_helpers.url_for(user.avatar)
  end

  def serialize_artist(artist)
    {
      id: artist.id,
      bio: artist.bio,
      created_at: artist.created_at,
      updated_at: artist.updated_at,
      user: {
        id: artist.user.id,
        name: artist.user.name,
        email: artist.user.email,
        role: artist.user.role,
        avatar: avatar_url(artist.user)
      }
    }
  end
end
