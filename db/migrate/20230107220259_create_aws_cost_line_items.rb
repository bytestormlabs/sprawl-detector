class CreateAwsCostLineItems < ActiveRecord::Migration[7.0]
  def change
    create_table :aws_cost_line_items do |t|
      t.date :date
      t.string :service
      t.string :region
      t.decimal :cost
      t.references :account, foreign_key: true
      t.timestamps
    end
  end
end
