require "base64"

class Token
  attr_accessor :body

  def initialize(body = nil)
    @body = body
  end

  def self.create(params)
    Token.new(params)
  end

  def to_base64
    encryptor = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31])
    encrypted_data = encryptor.encrypt_and_sign(JSON.pretty_generate(body))
    Base64.strict_encode64(encrypted_data).strip
  end

  def self.from_base64(input)
    encryptor = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31])
    begin
      result = encryptor.decrypt_and_verify(Base64.strict_decode64(input))
      JSON.parse(result)
    rescue
      raise InvalidTokenError
    end
  end

  def self.is_valid?(input)
    Token.from_base64(input)
    true
  rescue
    false
  end
end

class InvalidTokenError < StandardError
  def initialize(msg = "Invalid token.")
    super
  end
end
