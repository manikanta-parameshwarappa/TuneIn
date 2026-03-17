class UsersController < ApplicationController
  include Authenticatable

  def profile
    render json: {
      id: current_user.id,
      name: current_user.name,
      email: current_user.email
    }
  end
end
