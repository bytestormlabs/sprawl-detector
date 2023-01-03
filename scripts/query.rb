#!/usr/bin/ruby
require_relative "./load_app"
require "optparse"
require "terminal-table"
require "date"

options = {
  status: Status.find_by_name("Open")
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: scan.rb --account-id <account-id> --issue-type <issue-type>"

  opts.on("-a", "--account-id ACCOUNT_ID", "The account ID to scan.") do |account_id|
    options[:account_id] = account_id
  end

  opts.on("-t", "--issue-type ISSUE_TYPE", "The types of issues to look for.") do |issue_type|
    options[:issue_type] = issue_type
  end

  opts.on("-r", "--region REGION", "The region to look into.") do |region|
    options[:region] = region
  end

  opts.on("-s", "--status STATUS", "The status to look into.") do |status|
    options[:status] = Status.find_by_name(status)
  end
end.parse!


decorator = CostDecorator.new
command = CommandDecorator.new

running_total = 0.0
table = Terminal::Table.new do |t|
  t << [ "status", "scan", "category", "account_id", "resource_id", "issue_type", "region", "message", "monthly_cost" ]
  t.add_separator
  Finding.where(options).each do |finding|
    cost = decorator.decorate(finding)
    running_total = (running_total + cost) if !cost.nil?
    t << [
      finding.status.name,
      finding.scan&.id,
      finding.category,
      finding.account_id,
      finding.resource_id[0..70],
      finding.issue_type,
      finding.region,
      finding.message,
      "$#{sprintf('%.2f', cost || 0.0)}",
      # command.decorate(finding)
      # finding.metadata["description"] || finding.metadata["name"]
    ]
    # ] unless [
    #   "aws-ec2-ami-obsolete",
    #   "aws-ebs-snapshot-obsolete"
    # ].include?(finding.issue_type)
  end
end
puts table

puts "Grand total: $#{sprintf('%.2f', running_total.floor(2))}"
