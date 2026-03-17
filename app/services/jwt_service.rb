class JwtService
  SECRET = Rails.application.secret_key_base

  def self.encode(payload, exp)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue
    nil
  end
end