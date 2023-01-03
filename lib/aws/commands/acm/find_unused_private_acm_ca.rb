require_relative "../../checks/cloudwatch/private_ca_check"
require_relative "../command"
require "aws-sdk-acmpca"
require "aws-sdk-acm"
require "date"

class FindUnusedAcmPrivateCA < Command
  def execute(context)
    each_region do |region|
      client = Aws::ACMPCA::Client.new(region: region)
      acm_client = Aws::ACM::Client.new(region: region)

      certificates = acm_client.list_certificates.certificate_summary_list.map do |certificate|
        acm_client.describe_certificate(certificate_arn: certificate.certificate_arn).certificate
      end

      certificate_authorities = client.list_certificate_authorities.certificate_authorities
      certificate_authorities.each do |certificate_authority|
        next if certificate_authority.status != "ACTIVE"

        # See if there is a certificate that references this
        is_referenced_by_an_active_cert = certificates.any? do |certificate|
          certificate.certificate_authority_arn == certificate_authority.arn && certificate.status == "ISSUED"
        end

        !is_referenced_by_an_active_cert && check_certificate_issuance(client, context, region, certificate_authority)
      end
    end
  end

  def check_certificate_issuance(client, context, region, certificate_authority)
    if certificate_issuance_check.matches(context, region, certificate_authority.arn)
      f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/acmpca").find_or_create_by(
        issue_type: certificate_issuance_check.issue_type,
        resource_id: certificate_authority.arn,
        account_id: context.aws_account_id
      ).tap do |f|
        f.region = region
        f.message = certificate_issuance_check.message
        f.metadata = certificate_authority.to_h
        f.scan = context.scan
      end
      f.save!
    end
  end

  def certificate_issuance_check
    PrivateCACheck.new({
      issue_type: "aws-private-ca-unused",
      metric: "Success",
      attribute: "Operation",
      statistic: "Sum",
      namespace: "AWS/ACMPrivateCA",
      period: (24*60*60),
      message: "No certificates issued during time period",
      start_time: (DateTime.now - 180).to_s
    })
  end
end
