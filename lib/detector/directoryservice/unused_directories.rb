require "detector/support/cloudwatch"
require "aws-sdk-directoryservice"

class UnusedDirectories
  ISSUE_TYPE = "aws-directory-service-unused-directory"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::DirectoryService::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_directories) do |response|
      response.directory_descriptions.each do |directory_description|
        resource = scan.build_resource(region, resource_type, directory_description.name, directory_description)
        number_of_days = 30   # TODO: Refactor this
        authentications = directory_description.dns_ip_addrs.map do |ip_address|
          [
            check("AWS/DirectoryService", "NTLM Authentications")
              .in(region)
              .in_last(number_of_days)
              .with_dimension("Metric Category", "Security System-Wide Statistics")
              .with_dimension("Domain Controller IP", ip_address)
              .with_dimension("Directory ID", directory_description.directory_id)
              .with(scan.credentials),
            check("AWS/DirectoryService", "Kerberos Authentications")
              .in(region)
              .in_last(number_of_days)
              .with_dimension("Metric Category", "Security System-Wide Statistics")
              .with_dimension("Domain Controller IP", ip_address)
              .with_dimension("Directory ID", directory_description.directory_id)
              .with(scan.credentials)
          ]
        end

        authentications.flatten!

        resource.create_finding(scan, ISSUE_TYPE) if authentications.all?(&:indicates_zero_activity?)
      end
    end
  end

  def service_name
    "AWS Directory Service"
  end

  def resource_type
    "AWS::DirectoryService::MicrosoftAD"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days", "The number of days (since today) to check for activity.", 30)
    ]
  end
end
