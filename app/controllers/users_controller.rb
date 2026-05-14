class UsersController < ApplicationController
  include Authenticatable

  # GET /profile
  def profile
    render json: user_profile_json
  end

  # PATCH /profile
  def update
    case params[:type]
    when "avatar"
      update_avatar
    when "info"
      update_info
    when "password"
      update_password
    else
      render json: { error: "Invalid update type. Must be 'avatar', 'info', or 'password'." }, status: :bad_request
    end
  end

  private

  # --- Update Handlers ---

  def update_avatar
    unless params[:avatar].present?
      return render json: { error: "Avatar file is required" }, status: :unprocessable_entity
    end

    @current_user.avatar.attach(avatar_params[:avatar])

    if @current_user.avatar.attached?
      render json: user_profile_json, status: :ok
    else
      render json: { error: "Failed to attach avatar" }, status: :unprocessable_entity
    end
  end

  def update_info
    if @current_user.update(info_params)
      render json: user_profile_json, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_password
    current_password = params[:current_password]
    new_password = params[:new_password]
    password_confirmation = params[:password_confirmation]

    unless current_password.present? && new_password.present? && password_confirmation.present?
      return render json: { error: "current_password, new_password, and password_confirmation are required" }, status: :unprocessable_entity
    end

    unless @current_user.authenticate(current_password)
      return render json: { error: "Current password is incorrect" }, status: :unprocessable_entity
    end

    unless new_password == password_confirmation
      return render json: { error: "Passwords do not match" }, status: :unprocessable_entity
    end

    if @current_user.update(password: new_password, password_confirmation: password_confirmation)
      render json: user_profile_json, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # --- Strong Params ---

  def avatar_params
    params.permit(:avatar)
  end

  def info_params
    params.permit(:name, :email, :dob)
  end

  # --- Response Helper ---

  def user_profile_json
    {
      id: @current_user.id,
      name: @current_user.name,
      email: @current_user.email,
      dob: @current_user.dob,
      role: @current_user.role,
      avatar_url: @current_user.avatar.attached? ? url_for(@current_user.avatar) : nil
    }
  end
end
