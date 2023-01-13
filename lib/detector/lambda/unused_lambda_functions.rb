require "detector/support/cloudwatch"
require "aws-sdk-lambda"

class UnusedLambdaFunctions
  ISSUE_TYPE = "aws-lambda-unused-function"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::Lambda::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :list_functions) do |response|
      response.functions.each do |function|
        resource = scan.build_resource(region, resource_type, function.function_name, function)
        number_of_days = 30   # TODO: Refactor this
        invocations = check("AWS/Lambda", "Invocations")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("FunctionName", function.function_name)
          .with(scan.credentials)

        resource.create_finding(scan, ISSUE_TYPE) if invocations.indicates_zero_activity?
      end
    end
  end

  def service_name
    "AWS Lambda"
  end

  def resource_type
    "AWS::Lambda::Function"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
