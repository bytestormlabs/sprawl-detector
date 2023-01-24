class CreateIssueTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :issue_types do |t|
      t.string :code
      t.string :name
      t.text :description
      t.string :category
      t.string :service
      t.json :parameters
      t.timestamps
    end
  end
end
