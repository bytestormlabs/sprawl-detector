require "terminal-table"
require "cost/cost_calculator"

class Report
  attr_accessor :account_id

  def initialize(account_id)
    @account_id = account_id
  end

  LineItem = Struct.new(:region, :issue_type, :count, :total_cost)

  def execute
    calculator = CostCalculator.new

    table = Terminal::Table.new do |t|
      t << [ "region", "issue_type", "number_of_issues", "monthly_cost" ]
      t.add_separator

      results = Account.find_by_account_id(@account_id).findings.where(status: :open).group_by { |f| [ f.issue_type, f.resource.region ]}.map do |key, findings|
        issue_type = key.first
        region = key.last
        total_cost = findings.map do |finding| (calculator.decorate(finding.resource) || 0) end.sum
        LineItem.new(region, issue_type, findings.count, total_cost)
      end

      results.sort_by(&:total_cost).each do |line|
        t << [
          line.region, line.issue_type, line.count, "$#{sprintf('%.2f', line.total_cost || 0.0)}",
        ]
      end
    end
    puts table
  end
end
