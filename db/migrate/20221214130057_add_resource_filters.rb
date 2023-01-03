class AddResourceFilters < ActiveRecord::Migration[6.0]

  def change
    create_table :resource_filters do |t|
      t.string "name"
      t.string "value"
      t.string "filter_type", default: "attribute"
      t.timestamps
    end
    create_table :scheduled_operations do |t|
      t.string "operation_type"
    end
    add_reference :resource_filters, :scheduled_operation, foreign_key: true, index: true
  end
end
