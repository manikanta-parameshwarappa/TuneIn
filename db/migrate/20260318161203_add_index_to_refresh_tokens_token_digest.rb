class AddIndexToRefreshTokensTokenDigest < ActiveRecord::Migration[8.0]
  def change
    add_index :refresh_tokens, :token_digest
  end
end
