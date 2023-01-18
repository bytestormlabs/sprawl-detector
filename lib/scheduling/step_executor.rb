class StepExecutor
  attr_accessor :client, :step, :logger

  def initialize(client, step, logger)
    @client = client
    @step = step
    @logger = logger
  end

  def down
    # begin
    step.started!

    futures = find_resources.map do |resource|
      Concurrent::Future.execute do
        if client.is_stopped?(resource)
          logger.warn "#{resource} is already stopped... skipping"
          # No need to do anything....
          step.increment(:number_of_resources_skipped)
        else
          step.add_resource(resource.to_h)
          step.save

          logger.warn "Stopping resource #{resource}"
          client.stop(resource)
          (10 * 60 / 6).times do
            break if client.is_stopped?(resource)
            sleep 6
          end

          if client.is_stopped?(resource)
            logger.info "Successfully stopped..."
            step.increment(:number_of_resources_completed)
          else
            logger.warn "Resource didn't stop in 10 minutes... marking as skipped."
            step.increment(:number_of_resources_skipped)
          end
        end
      end
    end

    finalize_step(futures)
  end

  def up
    # begin
    step.started!

    # Find all resources for this resource_filter that were stopped and start them?

    last_step = Step.where(
      resource_filter: step.resource_filter,
      direction: :down
    ).where("metadata IS NOT NULL").order(:created_at).last

    futures = last_step.resources.map do |json|
      resource = json.deep_symbolize_keys
      Concurrent::Future.execute do
        # Stop it!
        client.start(resource)

        (10 * 60 / 6).times do
          refreshed = client.describe(resource)
          break if client.is_started?(refreshed)
          sleep 6
        end
      end
    end

    finalize_step(futures)
  end

  private

  def finalize_step(futures)
    futures.each do |future|
      future.value
      if future.reason
        logger.error future.reason
        step.failed!
        step.increment(:number_of_resources_skipped)
      end
    end
    step.stopped! unless step.failed?
  end

  def find_resources
    filters = step.resource_filter.filters.map(&:to_filter)
    resources = client.list_resources(filters)

    # step.metadata = resources.map(&:to_h)
    step.number_of_resources_found = resources.length
    step.save!

    resources
  end
end
