class AddRevokedToRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :refresh_tokens, :revoked, :boolean, default: false, null: false
  end
end
