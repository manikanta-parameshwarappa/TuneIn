class AuthController < ApplicationController
  def signup
    user = User.new(user_params)

    if user.save
      access_token, refresh_token, = TokenService.generate_tokens(user)

      set_refresh_cookie(refresh_token)

      render json: auth_response(user, access_token), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      access_token, refresh_token, = TokenService.generate_tokens(user)

      set_refresh_cookie(refresh_token)

      render json: auth_response(user, access_token)
    else
      render_unauthorized
    end
  end

  def refresh
    raw_token = cookies[:refresh_token]
    return render_unauthorized unless raw_token

    user = current_user_from_access_token
    return render_unauthorized unless user

    stored_token = TokenService.verify_refresh_token(user, raw_token)
    return render_unauthorized unless stored_token

    access_token, new_refresh_token, =
      TokenService.rotate_refresh_token(user, stored_token)

    set_refresh_cookie(new_refresh_token)

    render json: { access_token: access_token }
  end

  def logout
    raw_token = cookies[:refresh_token]

    if raw_token && current_user
      current_user.refresh_tokens.each do |token|
        if BCrypt::Password.new(token.token_digest) == raw_token
          token.destroy
        end
      end
    end

    cookies.delete(:refresh_token)
    head :ok
  end

  private

  def user_params
    params.permit(:name, :email, :password, :dob)
  end

  def auth_response(user, token)
    {
      access_token: token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        dob: user.dob
      }
    }
  end

  def set_refresh_cookie(token)
    cookies[:refresh_token] = {
      value: token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :strict
    }
  end

  def current_user_from_access_token
    header = request.headers["Authorization"]
    token = header.split(" ").last if header
    decoded = JwtService.decode(token)

    User.find_by(id: decoded[:user_id]) if decoded
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end