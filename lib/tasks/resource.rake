require "cost/cost_calculator"

namespace :resource do
  desc "Re-calculate the price for all resources"
  task recalculate_cost: :environment do
    calculator = CostCalculator.new

    Resource.where("estimated_cost IS NULL").each do |resource|
      estimated_cost = calculator.decorate(resource)
      resource.estimated_cost = estimated_cost
      resource.save if estimated_cost
    end
  end
end
