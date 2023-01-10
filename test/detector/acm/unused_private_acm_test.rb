require "detector/acm/unused_private_acm_ca"
require "base_aws_integration_test"

class UnusedPrivateAcmCaTest < ActiveSupport::TestCase
  detector = UnusedAcmPrivateCA.new

  test "has correct service name" do
    assert detector.service_name == "AWS Certificate Manager"
  end
  test "has correct resource type" do
    assert detector.resource_type == "AWS::ACMPCA::CertificateAuthority"
  end
  test "generates default settings" do
    assert detector.default_settings.count == 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    # Add test cases here.
  end
end
