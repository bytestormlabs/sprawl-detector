source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.0"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.4"

# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.4"
gem "mysql2"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 5.0"

gem "active_model_serializers"

gem "ox"
gem "devise"
gem "omniauth"
gem "faker"
gem "sekreto"

# AWS SDKs
gem "aws-sdk-acm"
gem "aws-sdk-acmpca"
gem "aws-sdk-cloudformation"
gem "aws-sdk-cloudtrail"
gem "aws-sdk-cloudwatch"
gem "aws-sdk-cloudwatchlogs"
gem "aws-sdk-costexplorer"
gem "aws-sdk-ec2"
gem "aws-sdk-ecr"
gem "aws-sdk-elasticache"
gem "aws-sdk-elasticloadbalancingv2"
gem "aws-sdk-elasticsearchservice"
gem "aws-sdk-databasemigrationservice"
gem "aws-sdk-lambda"
gem "aws-sdk-mq"
gem "aws-sdk-rds"
gem "aws-sdk-redshift"
gem "aws-sdk-route53resolver"
gem "aws-sdk-sagemaker"
gem "aws-sdk-secretsmanager"
gem "aws-sdk-pricing"
gem "aws-sdk-transfer"
gem "aws-sdk-wafv2"

gem "nokogiri"
gem "terminal-table"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "minitest-around"
  gem "vcr"
  gem "webmock"
end
