Sekreto.setup do |setup|
  setup.secrets_manager = Aws::SecretsManager::Client.new
  setup.prefix = Rails.env
  setup.is_allowed_env = -> { ENV.fetch("USE_SECRETS", false) }
  setup.fallback_lookup = ->(secret_id) { Secrets.where(name: secret_id).pluck(:value).first }
end
