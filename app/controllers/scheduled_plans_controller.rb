class ScheduledPlansController < ApplicationController
  def index
    @current_user.accounts.map do |account|
      account.scheduled_plans
    end.flatten
  end

  def create
    sp = ScheduledPlan.new(allowed_params.slice(:account_id, :up_schedule, :down_schedule, :name))

    allowed_params["resource_filters"].each do |resource_filter_params|
      resource_filter = ResourceFilter.new(resource_filter_params.slice(:region, :resource_type))
      resource_filter.filters = resource_filter_params["filters"].map do |filter_params|
        Filter.new(filter_params.slice(:filter_type, :name, :value))
      end
      sp.resource_filters << resource_filter
    end

    if sp.valid?
      if sp.save
        render json: sp, status: 200
      else
        render json: sp.errors, status: 409
      end
    else
      render json: sp.errors, status: 409
    end
  end

  private
  def allowed_params
    params.permit!
  end
end
