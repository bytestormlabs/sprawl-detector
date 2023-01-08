class CreateFindings < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts do |t|
      t.string :account_id, unique: true
      t.string :external_id
      t.references :tenant, foreign_key: true
      t.timestamps
    end
    create_table :resolutions do |t|
      t.string :name
      t.timestamps
    end
    create_table :scans do |t|
      t.references :account, foreign_key: true
      t.string :status
      t.timestamps
    end
    create_table :resources do |t|
      t.string :resource_id
      t.string :resource_type
      t.string :region
      t.json :metadata
      t.references :account, foreign_key: true
      t.references :scan, foreign_key: true
      t.timestamps
    end
    create_table :findings do |t|
      t.string :category
      t.string :issue_type
      t.string :status
      t.decimal :estimated_cost, :precision=>64, :scale=>12
      t.json :params
      t.references :resource, foreign_key: true
      t.references :account, foreign_key: true
      t.references :resolution, foreign_key: true, null: true
      t.references :scan, foreign_key: true, null: true
      t.timestamps
    end
  end
end
