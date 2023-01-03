#!/usr/bin/ruby
require "optparse"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: scan.rb --account-id <account-id> --tenant-id <tenant-id>"

  opts.on("-a", "--account-id ACCOUNT_ID", "The account ID to scan.") do |account_id|
    options[:account_id] = account_id
  end

  opts.on("-t", "--tenant-id TENANT_ID", "The tenant ID to associate findings for.") do |tenant_id|
    options[:tenant_id] = tenant_id
  end
end.parse!

raise "Missing required parameter --account-id" if options[:account_id].nil?
# raise "Missing required parameter --tenant-id" if options[:tenant_id].nil?

require_relative "./load_app"

ctx = ScanContext.new(options)

ScanForFindings.new.execute(ctx)
#
#
# pp ctx
# commands = [
#   # FindUnusedDatabases,
#   FindScheduledInstanceCandidates
# ]
#
# commands.map do |command|
#   command.new.execute(ctx)
# end
