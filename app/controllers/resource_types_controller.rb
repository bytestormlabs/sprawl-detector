class ResourceTypesController < ApplicationController
  def index
    render json: ResourceFilter.resource_configurations
  end
end
