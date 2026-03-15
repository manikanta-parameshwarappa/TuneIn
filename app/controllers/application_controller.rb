class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # This makes Rails behave like an API-only app (no HTML views)

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def encode_token(payload, exp)
    payload[:exp] = exp.to_i
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end

  def decode_token(token)
    begin
      JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')
    rescue JWT::DecodeError
      nil
    end
  end

  def current_user
    header = request.headers['Authorization']
    if header
      token = header.split(' ')[1]
      decoded = decode_token(token)
      if decoded
        user_id = decoded[0]['user_id']
        @current_user ||= User.find_by(id: user_id)
      end
    end
  end

  def authorize_request
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end

  private

  def record_not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def parameter_missing(error)
    render json: { error: error.message }, status: :bad_request
  end

  def record_invalid(error)
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end
  

  allow_browser versions: :modern
end
