class AddCloudtrailFieldsToResources < ActiveRecord::Migration[7.0]
  def change
    add_column :resources, :created_by, :string, nullable: true
    add_column :resources, :created_on, :date, nullable: true
    add_column :resources, :request_id, :string, nullable: true
    add_column :resources, :event_id, :string, nullable: true
  end
end
