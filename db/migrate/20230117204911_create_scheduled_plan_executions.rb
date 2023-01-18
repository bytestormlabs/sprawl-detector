class CreateScheduledPlanExecutions < ActiveRecord::Migration[7.0]
  def change
    create_table :scheduled_plan_executions do |t|
      t.references :scheduled_plan
      t.string :status
      t.datetime :timestamp
      t.timestamps
    end
    create_table :steps do |t|
      t.references :scheduled_plan_execution, foreign_key: true
      t.references :resource_filter, foreign_key: true
      t.string :status
      t.string :direction
      t.integer :number_of_resources_found, default: 0
      t.integer :number_of_resources_skipped, default: 0
      t.integer :number_of_resources_completed, default: 0
      t.json :metadata
      t.timestamps
    end
  end
end
