require "checks/cloudwatch/private_ca_check"
require "aws-sdk-acmpca"
require "aws-sdk-acm"
require "date"
require "detector/support/cloudwatch"

class UnusedAcmPrivateCA
  ISSUE_TYPE = "aws-private-ca-unused"
  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::ACMPCA::Client.new(region: region, credentials: scan.credentials)
    acm_client = Aws::ACM::Client.new(region: region, credentials: scan.credentials)

    certificates = []
    loop_until_finished(acm_client, :list_certificates) do |response|
      certificates << response.certificate_summary_list.map do |certificate|
        acm_client.describe_certificate(certificate_arn: certificate.certificate_arn).certificate
      end
    end
    certificates.flatten


    certificate_authorities = client.list_certificate_authorities.certificate_authorities
    certificate_authorities.each do |certificate_authority|
      resource = scan.build_resource(region, "AWS::ACMPCA::CertificateAuthority", certificate_authority.arn, certificate_authority)

      is_certificate_authority_referenced_by_an_active_cert = certificates.any? do |certificate|
        certificate.certificate_authority_arn == certificate_authority.arn && certificate.status == "ISSUED"
      end

      number_of_days = 90   # TODO: Refactor this
      cloudwatch_issue_certificate_metrics = check("AWS/ACMPrivateCA", "Success")
        .for_last(number_of_days).days
        .with_dimension("Operation", "IssueCertificate")
        .with_dimension("PrivateCAArn", certificate_authority.arn)

      resource.create_finding(ISSUE_TYPE, certificate_authority) if [
        certificate_authority.status == "ACTIVE",
        !is_certificate_authority_referenced_by_an_active_cert,
        cloudwatch_issue_certificate_metrics.indicates_zero_activity?
      ].all?
    end
  end

  def service_name
    "AWS Certificate Manager"
  end

  def resource_type
    "AWS::ACMPCA::CertificateAuthority"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
