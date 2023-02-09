class RemoveAuthenticationToken < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :authentication_token
  end
end
