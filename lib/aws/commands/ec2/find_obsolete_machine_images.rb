require_relative "../command"
require "aws-sdk-ec2"
require "date"

class FindObsoleteMachineImages < Command
  def execute(context)
    each_region do |region|
      ec2_client = Aws::EC2::Client.new(region: region)
      images = ec2_client.describe_images(owners: [context.aws_account_id]).images

      context.logger.debug "Found #{images.size} machine images."
      machine_images_in_use = ec2_client.describe_instances.reservations.map do |reservation|
        reservation.instances.map do |instance|
          instance.image_id
        end
      end.flatten.compact.uniq

      images.each do |image|
        next if machine_images_in_use.include? image.image_id

        if image.creation_date < (DateTime.now - 180) # TODO: Refactor this into a parameter.
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ec2").find_or_create_by(
            issue_type: "aws-ec2-ami-obsolete",
            resource_id: image.image_id,
            account_id: context.aws_account_id
          ).tap do |f|
            f.region = region
            f.message = "Amazon EC2 machine image is obsolete."
            f.metadata = image.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end
end
