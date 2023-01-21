class FindingSummary

  attr_accessor :account_id, :account, :region, :priority, :issue_type, :count, :estimated_cost

  def self.find_by_tenant(id)
    sql = """
      SELECT accounts.name as account, region, issue_type, COUNT(*) as count, SUM(resources.estimated_cost) as estimated_cost
      FROM findings
        JOIN resources on findings.resource_id = resources.id
        JOIN accounts on findings.account_id = accounts.id
      WHERE accounts.tenant_id = '#{id}' AND findings.status = 'OPEN'
      GROUP BY 1, 2, 3
    """

    puts sql

    results = ActiveRecord::Base.connection.exec_query(sql)

    results.rows.map do |row|
      summary = FindingSummary.new

      results.columns.each_with_index do |col, i|
        method = "#{col}="
        value = row[i]
        summary.send(method, row[i]) if summary.respond_to?(method)
      end

      if (summary.estimated_cost.nil?)
        summary.priority = "Low"
      elsif (summary.estimated_cost > 400)
        summary.priority = "High"
      elsif (summary.estimated_cost > 100)
        summary.priority = "Medium"
      else
        summary.priority = "Low"
      end

      summary
    end
  end
end
