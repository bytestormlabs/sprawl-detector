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
end.parse!

command = CommandDecorator.new

Finding.where(options).each do |finding|
  puts "#{command.decorate(finding)}"
end
