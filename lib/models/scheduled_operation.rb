require "aws-sdk-ec2"

class ScheduledOperation < ActiveRecord::Base
  validates :operation_type, presence: true
  has_many :resource_filters, autosave: true

  def execute
    if operation_type == "stop-ec2-instances"
      ids = get_ec2_instance_ids
      stop_instances(ids)
    elsif operation_type == "start-ec2-instances"
      ids = get_ec2_instance_ids
      start_instances(ids)
    elsif operation_type == "stop-rds-instances"
      id = get_rds_db_identifier
      stop_db_instance(id)
    elsif operation_type == "start-rds-instances"
      id = get_rds_db_identifier
      start_db_instance(id)
    else
      raise "Unrecognized operation_type #{operation_type}"
    end
  end

  def get_ec2_instance_ids
    puts "entering get_ec2_instance_ids"
    client = Aws::EC2::Client.new(region: "us-east-1")
    filters = resource_filters.map(&:to_filter)

    reservations = client.describe_instances(filters: filters)[:reservations]
    reservations.map do |reservation|
      reservation.instances.map do |instance|
        instance.instance_id
      end
    end.flatten
  end

  def get_rds_db_identifier
    puts "entering get_rds_instance_ids"
    client = Aws::RDS::Client.new(region: "us-east-1")
    filters = resource_filters.map(&:to_filter)

    puts "filters: #{filters}"
    instances = client.describe_db_instances(filters: filters)[:db_instances]
    instances.map do |instance|
      instance.db_instance_identifier
    end.flatten
  end

  def stop_instances(instance_ids)
    puts "entering stop_instances(instance_ids = #{instance_ids})"
    client = Aws::EC2::Client.new(region: "us-east-1")
    client.stop_instances(instance_ids: instance_ids)
  end

  def start_instances(instance_ids)
    puts "entering start_instances(instance_ids = #{instance_ids})"
    client = Aws::EC2::Client.new(region: "us-east-1")
    client.start_instances(instance_ids: instance_ids)
  end

  def stop_db_instance(ids)
    client = Aws::RDS::Client.new(region: "us-east-1")
    ids.each do |id|
      client.stop_db_instance(db_instance_identifier: id)
    end
  end

  def start_db_instance(ids)
    client = Aws::RDS::Client.new(region: "us-east-1")
    ids.each do |id|
      client.start_db_instance(db_instance_identifier: id)
    end
  end
end
