require_relative "../../lib/models/status"
require_relative "../../lib/models/resolution"

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
      t.references :resolution, foreign_key: true
      t.timestamps
    end

    Status.find_or_create_by(name: "New").save!
    Status.find_or_create_by(name: "Open").save!
    Status.find_or_create_by(name: "Closed").save!

    Resolution.find_or_create_by(name: "Ignored").save!
    Resolution.find_or_create_by(name: "Closed").save!
  end
end
