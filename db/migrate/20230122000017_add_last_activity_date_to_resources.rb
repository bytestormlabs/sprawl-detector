class AddLastActivityDateToResources < ActiveRecord::Migration[7.0]
  def change
    add_column :resources, :last_activity_date, :date, nullable: true
    add_column :resources, :creation_date, :date, nullable: true
  end
end
