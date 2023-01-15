require "aws-sdk-kms"
require "aws-sdk-sts"
require "base64"

role_arn = "arn:aws:iam::163788863765:role/BS-SprawlDetector"

sts = Aws::STS::Client.new(region: "us-east-2")
credentials = sts.assume_role(
  role_session_name: "KmsEncryptionTest",
  role_arn: role_arn,
  external_id: "abc-123-def-456"
)

kms = Aws::KMS::Client.new(region: "us-east-2", credentials: credentials)

result = kms.encrypt(
  key_id: "alias/bytestorm-labs",
  plaintext: "this is a test"
)

puts "Base64 encoded: #{Base64.encode64(result.ciphertext_blob.to_s)}"

decrypt_result = kms.decrypt(
  key_id: "alias/bytestorm-labs",
  ciphertext_blob: result.ciphertext_blob
)

puts "Decrypted: #{decrypt_result.plaintext}"

kms.delete_alias(
  alias_name: "alias/bytestorm-labs"
)
