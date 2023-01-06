class AddEstimatedCostToFinding < ActiveRecord::Migration[7.0]
  def change
    add_column :findings, :cost, :double, nullable: true
  end
end
