class AuthController < ApplicationController
  before_action :authorize_request, only: [:logout]

  # 📝 SIGNUP
  def signup
    user = User.new(user_params)

    if user.save
      render_tokens(user)
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # 🔐 LOGIN
  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      render_tokens(user)
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  # 🔁 REFRESH TOKEN
  def refresh
    token = params[:refresh_token]

    refresh_token = RefreshToken.find_by(token: token)

    if refresh_token.nil? || refresh_token.revoked || refresh_token.expired?
      return render json: { error: "Invalid refresh token" }, status: :unauthorized
    end

    # 🔄 Token Rotation (recommended)
    refresh_token.revoke!

    new_refresh_token = create_refresh_token(refresh_token.user)
    access_token = JwtService.encode(user_id: refresh_token.user.id)

    render json: {
      access_token: access_token,
      refresh_token: new_refresh_token.token
    }
  end

  # 🚪 LOGOUT
  def logout
    token = params[:refresh_token]

    refresh_token = RefreshToken.find_by(token: token)
    refresh_token&.revoke!

    render json: { message: "Logged out successfully" }
  end

  private

  def render_tokens(user)
    access_token = JwtService.encode(user_id: user.id)
    refresh_token = create_refresh_token(user)

    render json: {
      access_token: access_token,
      refresh_token: refresh_token.token
    }
  end

  def create_refresh_token(user)
    user.refresh_tokens.create!(
      token: SecureRandom.hex(64),
      expires_at: 7.days.from_now
    )
  end

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end

  # 🔒 AUTH MIDDLEWARE
  def authorize_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header

    decoded = JwtService.decode(token)

    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end