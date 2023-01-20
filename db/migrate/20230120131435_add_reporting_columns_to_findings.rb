class AddReportingColumnsToFindings < ActiveRecord::Migration[7.0]
  def change
    add_column :resources, :estimated_cost, :decimal
    add_column :findings, :priority, :string
  end
end
