class UsersController < ApplicationController

  before_action :authorize_request, only: [:profile]

  # POST /signup
  def create
    user = User.new(user_params)
    if user.save
      access_token  = encode_token({ user_id: user.id }, 15.minutes.from_now)
      refresh_token = encode_token({ user_id: user.id }, 7.days.from_now)

      cookies.signed[:refresh_token] = {
        value: refresh_token,
        httponly: true,
        secure: Rails.env.production?,
        expires: 7.days.from_now
      }

      render json: { user: user, access_token: access_token }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /login
  def login
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
      access_token  = encode_token({ user_id: user.id }, 15.minutes.from_now)
      refresh_token = encode_token({ user_id: user.id }, 7.days.from_now)

      cookies.signed[:refresh_token] = {
        value: refresh_token,
        httponly: true,
        secure: Rails.env.production?,
        expires: 7.days.from_now
      }

      render json: { user: user, access_token: access_token }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # POST /refresh
  def refresh
    refresh_token = cookies.signed[:refresh_token]
    decoded = decode_token(refresh_token)

    if decoded
      user = User.find_by(id: decoded[0]["user_id"])
      if user
        new_access_token = encode_token({ user_id: user.id }, 15.minutes.from_now)
        render json: { access_token: new_access_token }, status: :ok
      else
        render json: { error: "Invalid refresh token" }, status: :unauthorized
      end
    else
      render json: { error: "No refresh token" }, status: :unauthorized
    end
  end

  # DELETE /logout
  def logout
    cookies.delete(:refresh_token)
    render json: { message: "Logged out successfully" }, status: :ok
  end

  # GET /profile
  def profile
    render json: current_user
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end
