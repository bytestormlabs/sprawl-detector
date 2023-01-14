require "terminal-table"
require "cost/cost_calculator"

class Report
  attr_accessor :account_id

  def initialize(account_id = nil)
    @account_id = account_id || ENV.fetch("AWS_ACCOUNT_ID")
  end

  LineItem = Struct.new(:region, :resource_type, :issue_type, :count, :total_cost)

  def execute
    calculator = CostCalculator.new

    results = Account.find_by_account_id(@account_id).findings.where(status: :open).group_by { |f| [f.issue_type, f.resource.region] }.map do |key, findings|
      issue_type = key.first
      region = key.last
      total_cost = findings.map { |finding| (calculator.decorate(finding.resource) || 0) }.sum
      LineItem.new(region, findings.first.resource.resource_type, issue_type, findings.count, total_cost)
    end

    table = Terminal::Table.new do |t|
      t << ["region", "resource_type", "issue_type", "number_of_issues", "monthly_cost"]
      t.add_separator

      results.sort_by(&:total_cost).each do |line|
        t << [
          line.region, line.resource_type, line.issue_type, line.count, "$#{sprintf("%.2f", line.total_cost || 0.0)}"
        ]
      end
    end
    puts table

    puts "Total: $#{results.sum(&:total_cost)}"
  end
end
