class CreateScheduledPlans < ActiveRecord::Migration[7.0]
  def change
    create_table :scheduled_plans do |t|
      t.references :account, foreign_key: true
      t.string :up_schedule
      t.string :down_schedule
      t.string :name
      t.timestamps
    end
    create_table :resource_filters do |t|
      t.string :region
      t.string :resource_type
      t.integer :ordinal
      t.references :scheduled_plan, foreign_key: true
      t.timestamps
    end
    create_table :filters do |t|
      t.string :name
      t.string :value
      t.string :filter_type, default: "attribute"
      t.references :resource_filter, foreign_key: true
      t.timestamps
    end
  end
end
