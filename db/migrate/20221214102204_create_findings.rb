class CreateFindings < ActiveRecord::Migration[6.0]
  def change
    create_table :statuses do |t|
      t.string "name"
      t.timestamps
    end
    create_table :resolutions do |t|
      t.string "name"
      t.timestamps
    end
    create_table :findings do |t|
      t.string "category"
      t.string "account_id"
      t.string "resource_id"
      t.string "issue_type"
      t.string "region"
      t.string "message"
      t.json "metadata"

      t.references :status, foreign_key: true
      t.references :resolution, foreign_key: true, null: true
      t.timestamps
    end
  end
end
