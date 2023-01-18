class StepExecutor
  attr_accessor :client, :step

  def initialize(client, step)
    @client = client
    @step = step
  end

  def down
    # begin
    step.started!

    futures = find_resources.map do |resource|
      Concurrent::Future.execute do
        # Stop it!
        client.stop(resource)

        completed = false
        (10 * 60 / 6).times do
          if client.is_stopped?(resource)
            step.increment("number_of_resources_completed")
            completed = true
            break
          end
          sleep 6
        end
        step.increment("number_of_resources_skipped") unless completed
      end
    end

    futures.map(&:value)
    errors = futures.map(&:reason).filter

    if errors.any?
      step.failed!
      errors.count.times do
        step.increment("number_of_resources_skipped")
      end
    else
      step.stopped!
    end
  end

  private
  def find_resources
    filters = step.resource_filter.filters.map(&:to_filter)
    resources = client.list_resources(filters)

    # step.metadata = resources.respond_to?(:to_h) ? resources.to_h : resources
    step.number_of_resources_found = resources.length
    step.save!

    resources
  end
end
