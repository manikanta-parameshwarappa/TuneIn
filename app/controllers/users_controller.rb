class UsersController < ApplicationController
  include Authenticatable

  def profile
    render json: @current_user
  end
end
