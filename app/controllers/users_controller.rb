class UsersController < ApplicationController
  include Authenticatable

  def profile
    render json: {name: @current_user.name , email: @current_user.email, dob: @current_user.dob}
  end
end
