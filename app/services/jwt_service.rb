class JwtService
  SECRET = Rails.application.credentials.secret_key_base

  def self.encode(payload, exp = 15.minutes.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, 'HS256') # explicitly set algorithm
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, { algorithm: 'HS256' })[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end
end