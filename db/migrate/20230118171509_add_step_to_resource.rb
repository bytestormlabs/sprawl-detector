class AddStepToResource < ActiveRecord::Migration[7.0]
  def change
    add_reference :resources, :step, foreign_key: true
  end
end
