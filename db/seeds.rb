# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Status.find_or_create_by(name: "New").save!
Status.find_or_create_by(name: "Open").save!
Status.find_or_create_by(name: "Closed").save!

Resolution.find_or_create_by(name: "Ignored").save!
Resolution.find_or_create_by(name: "Closed").save!

Tenant.find_or_create_by(name: "ByteStorm Labs").save!
account = Account.find_or_create_by(account_id: "163788863765", tenant: Tenant.find_by_name("ByteStorm Labs"))
account.create_random_external_id
account.save!
