require "base64"

crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31])
# encrypted_data = crypt.encrypt_and_sign(JSON.pretty_generate({
#   email: "frank@bytestormlabs.com",
#   tenant: {
#     name: "ByteStorm Labs"
#   }
# }))

# token = Base64.encode64(encrypted_data).gsub("\n", "")
token = "RHVRSTBhRWlGaXBCdXQ5N3dyS09Eb0E3cHBCVW0vbUpreTI4bThJWWRUQ3Bv\neEwxdlN2SFZhWDdzbU9GZTVVU0swMD0tLS9PZ1B2SmZLOG5Fbi9rNm4tLXMz\nR0dHWk9lT0g5UU05TWRIbVkrZkE9PQ==\n"

puts "encrypted: #{token}"

result = JSON.parse(crypt.decrypt_and_verify(Base64.decode64(token)))

puts "decrypted: #{result}"
