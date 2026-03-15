class ChangeRoleToStringInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column :users, :role, :string, default: "listener", null: false
  end
end
