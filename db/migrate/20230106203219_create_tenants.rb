class CreateTenants < ActiveRecord::Migration[7.0]
  def change
    create_table :tenants do |t|
      t.string :name
      t.timestamps
    end
    add_reference :users, :tenant
  end
end
