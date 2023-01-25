class FindingSummary
  attr_accessor :account_id, :account, :region, :priority, :issue_type, :count, :estimated_cost
  attr_accessor :name, :category, :service, :description

  def self.find_by_tenant(id)
    sql = "
      SELECT accounts.account_id as account_id, accounts.name as account, region, issue_type, COUNT(*) as count, SUM(resources.estimated_cost) as estimated_cost
      FROM findings
        JOIN resources on findings.resource_id = resources.id
        JOIN accounts on findings.account_id = accounts.id
      WHERE accounts.tenant_id = '#{id}' AND findings.status = 'OPEN'
      GROUP BY 1, 2, 3, 4
    "

    results = ActiveRecord::Base.connection.exec_query(sql)

    results.rows.map do |row|
      summary = FindingSummary.new

      results.columns.each_with_index do |col, i|
        method = "#{col}="
        value = row[i]
        summary.send(method, value) if summary.respond_to?(method)
      end

      %w[name category service description].each do |field|
        value = IssueType.find_by_code(summary.issue_type).send(field)
        summary.send("#{field}=", value) if summary.respond_to?(field)
      end

      summary.priority = if summary.estimated_cost.nil?
        "Low"
      elsif summary.estimated_cost > 400
        "High"
      elsif summary.estimated_cost > 100
        "Medium"
      else
        "Low"
      end

      summary
    end
  end
end
