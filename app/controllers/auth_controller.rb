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
    raw_token = cookies[:refresh_token]
    return render json: { error: "Unauthorized" }, status: :unauthorized unless raw_token

    digest = Digest::SHA256.hexdigest(raw_token)
    refresh_token = RefreshToken.active.find_by(token_digest: digest)

    return render json: { error: "Invalid refresh token" }, status: :unauthorized unless refresh_token

    refresh_token.revoke!
    new_refresh_token = create_refresh_token(refresh_token.user)
    access_token = JwtService.encode(user_id: refresh_token.user.id)

    cookies[:refresh_token] = {
      value: new_refresh_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :strict
    }

    current_user = User.find_by(id: refresh_token.user.id)

    render json: { access_token: access_token, user: {
        id: current_user.id,
        name: current_user.name,
        email: current_user.email
    } }

  end

  # 🚪 LOGOUT
  def logout
    raw_token = cookies[:refresh_token]
    if raw_token
      digest = Digest::SHA256.hexdigest(raw_token)
      token = RefreshToken.find_by(token_digest: digest)
      token&.revoke!
    end

    cookies.delete(:refresh_token)
    render json: { message: "Logged out successfully" }
  end

  private

  def render_tokens(user)
    access_token = JwtService.encode(user_id: user.id)
    raw_refresh_token = create_refresh_token(user)

    cookies[:refresh_token] = {
      value: raw_refresh_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :strict
    }

    render json: {
      access_token: access_token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      }
    }
  end

  def create_refresh_token(user)
    raw_refresh_token = SecureRandom.hex(64)
    token_digest = Digest::SHA256.hexdigest(raw_refresh_token)

    user.refresh_tokens.create!(
      token_digest: token_digest,
      expires_at: 7.days.from_now
    )

    raw_refresh_token
  end

  def user_params
    params.permit(:name, :email, :dob, :password, :password_confirmation)
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
