class CreateScan < ActiveRecord::Migration[6.0]

  def change
    create_table :scans do |t|
      t.timestamps
    end
    add_reference :findings, :scan
  end
end
