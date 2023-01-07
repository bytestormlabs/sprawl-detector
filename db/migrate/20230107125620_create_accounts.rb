class CreateAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :accounts do |t|
      t.string :account_id, unique: true
      t.string :external_id
      t.references :tenant, foreign_key: true
      t.timestamps
    end
    rename_column :findings, :account_id, :aws_account_id
    add_reference :findings, :account

    execute "INSERT INTO accounts (account_id, created_at, updated_at) SELECT DISTINCT findings.aws_account_id as account_id, date('now'), date('now') FROM findings"
    execute "UPDATE findings SET account_id = (SELECT accounts.id FROM accounts WHERE accounts.account_id = findings.aws_account_id);"
  end
end
