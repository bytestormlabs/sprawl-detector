# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Resolution.find_or_create_by(name: "Ignored").save!
Resolution.find_or_create_by(name: "Closed").save!

Tenant.find_or_create_by(name: "ByteStorm Labs").save!
account = Account.find_or_create_by(account_id: "163788863765", tenant: Tenant.find_by_name("ByteStorm Labs"))
account.external_id = "abc-123-def-456"
account.save!

ScheduledPlan.new(account: account, resource_filters: [
  ResourceFilter.new(
    resource_type: "AWS::AutoScaling::AutoScalingGroup",
    region: "us-east-2"
  )
]).save!

if File.exist?("db/development-seeds.rb")
  require_relative "./development-seeds"
end

if File.exist?("lib/detector/issue-types.yaml")
  require "yaml"
  contents = YAML.load_file("lib/detector/issue-types.yaml")
  contents["categories"].each do |category|
    category_nm = category["name"]
    # category_code = category["code"]

    category["issue-types"].each do |descriptor|
      issue_type = IssueType.find_or_create_by(code: descriptor["code"])
      issue_type.name = descriptor["name"]
      issue_type.description = descriptor["description"]
      issue_type.category = category_nm
      issue_type.service = descriptor["service"]
      issue_type.parameters = descriptor["parameters"] || []
      descriptor["parameters"]&.each do |parameter|
        setting = issue_type.settings.find_or_create_by(key: parameter["key"])
        setting.value = parameter["default"]
        setting.description = parameter["description"]
      end
      issue_type.settings.find_or_create_by(key: "enabled", value: "true", description: "")
      issue_type.save!
    end
  end
end
