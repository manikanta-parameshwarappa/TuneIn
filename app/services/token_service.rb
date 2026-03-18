class TokenService
  ACCESS_EXPIRY = 15.minutes
  REFRESH_EXPIRY = 30.days

  def self.generate_tokens(user)
    access_token = JwtService.encode({ user_id: user.id }, ACCESS_EXPIRY.from_now)

    raw_refresh_token = SecureRandom.hex(64)
    token_digest = Digest::SHA256.hexdigest(raw_refresh_token)

    user.refresh_tokens.create!(
      token_digest: token_digest,
      expires_at: REFRESH_EXPIRY.from_now
    )

    [access_token, raw_refresh_token]
  end

  def self.verify_refresh_token(user, raw_token)
    digest = Digest::SHA256.hexdigest(raw_token)
    user.refresh_tokens.active.find_by(token_digest: digest)
  end

  def self.rotate_refresh_token(user, old_token_record)
    old_token_record.update(revoked: true)
    generate_tokens(user)
  end

  def self.revoke_refresh_token(user, raw_token)
    digest = Digest::SHA256.hexdigest(raw_token)
    token = user.refresh_tokens.find_by(token_digest: digest)
    token&.update(revoked: true)
  end
end