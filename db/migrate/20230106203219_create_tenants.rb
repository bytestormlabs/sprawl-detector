class CreateTenants < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :tenant
  end
end
