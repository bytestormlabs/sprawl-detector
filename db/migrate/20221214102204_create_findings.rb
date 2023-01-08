class CreateFindings < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts do |t|
      t.string :account_id, unique: true
      t.string :external_id
      t.references :tenant, foreign_key: true
      t.timestamps
    end
    create_table :statuses do |t|
      t.string :name
      t.timestamps
    end
    create_table :resolutions do |t|
      t.string :name
      t.timestamps
    end
    create_table :scans do |t|
      t.references :accounts, foreign_key: true
      t.timestamps
    end
    create_table :resources do |t|
      t.string :resource_id
      t.string :resource_type
      t.json :metadata
      t.references :accounts, foreign_key: true
      t.references :scans, foreign_key: true
      t.timestamps
    end
    create_table :findings do |t|
      t.string :category
      t.string :issue_type
      t.string :message
      t.decimal :estimated_cost, :precision=>64, :scale=>12
      t.references :account, foreign_key: true
      t.references :status, foreign_key: true
      t.references :resolution, foreign_key: true, null: true
      t.references :scan, foreign_key: true, null: true
      t.timestamps
    end
  end
end
