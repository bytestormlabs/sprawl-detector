class CreateRecommendations < ActiveRecord::Migration[7.0]
  def change
    create_table :recommendations do |t|
      t.string :name
      t.text :description
      t.string :category
      t.timestamps
    end
  end
end
