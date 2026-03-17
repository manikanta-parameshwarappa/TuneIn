class TokenService
  ACCESS_EXPIRY = 15.minutes
  REFRESH_EXPIRY = 30.days

  def self.generate_tokens(user)
    access_token = JwtService.encode({ user_id: user.id }, ACCESS_EXPIRY.from_now)

    raw_refresh_token = SecureRandom.hex(64)
    token_digest = BCrypt::Password.create(raw_refresh_token)

    refresh_record = user.refresh_tokens.create!(
      token_digest: token_digest,
      expires_at: REFRESH_EXPIRY.from_now
    )

    [access_token, raw_refresh_token, refresh_record]
  end

  def self.verify_refresh_token(user, raw_token)
    user.refresh_tokens.active.find do |token|
      BCrypt::Password.new(token.token_digest) == raw_token
    end
  end

  def self.rotate_refresh_token(user, old_token_record)
    old_token_record.destroy
    generate_tokens(user)
  end
end