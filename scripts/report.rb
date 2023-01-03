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
  t << [ "account_id", "category", "issue_type", "number_of_issues", "monthly_cost" ]
  t.add_separator
  Finding.where(options).where('resolution_id IS NULL').group_by(&:account_id).each do |account_id, grouped_by_account|
    puts "Found #{grouped_by_account.size} findings for #{account_id}"
    grouped_by_account.group_by(&:category).each do |category, grouped_by_category|
      puts " Found #{grouped_by_category.size} findings for #{account_id}.#{category}"
      grouped_by_category.group_by(&:issue_type).each do |issue_type, grouped_by_issue_type|
        puts "  Found #{grouped_by_issue_type.size} findings for #{account_id}.#{category}.#{issue_type}"
        subtotal = 0.0
        grouped_by_issue_type.each do |finding|
          cost = decorator.decorate(finding)
          subtotal = subtotal + cost if !cost.nil?
          running_total = (running_total + cost) if !cost.nil?
        end
        t << [
          account_id,
          category,
          issue_type,
          grouped_by_issue_type.size,
          "$#{sprintf('%.2f', subtotal || 0.0)}",
          # command.decorate(finding)
          # finding.metadata["description"] || finding.metadata["name"]
        ]
      end
    end
    # end
  end
end
puts table

puts "Grand total: $#{sprintf('%.2f', running_total.floor(2))}"
