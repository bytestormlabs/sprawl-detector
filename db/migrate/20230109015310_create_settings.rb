class CreateSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :settings do |t|
      t.string :data_type, default: "integer"
      t.string :name
      t.text :description, null: true
      t.string :value
      t.references :account, foreign_key: true
      t.references :tenant, foreign_key: true
      t.timestamps
    end
  end
end
