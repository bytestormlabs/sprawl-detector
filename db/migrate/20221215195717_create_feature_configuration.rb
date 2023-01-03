class CreateFeatureConfiguration < ActiveRecord::Migration[6.0]

  def change
    create_table :feature_configurations do |t|
      t.string "tenant_id"
      t.string "key"
      t.string "value"
      t.timestamps
    end
  end
end
