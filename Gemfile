source "https://rubygems.org"

ruby "3.3.0"

gem "rails", "8.0.3"

gem "sqlite3"

gem "puma", ">= 5.0"

group :production do
  gem "pg"
end

gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "bootsnap", require: false

# CORS
gem "rack-cors"

# Auth
gem "devise"
gem "jwt"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"
gem "cancancan"

gem "aws-sdk-s3", require: false

# SendGrid HTTP API (avoids SMTP port blocks on Railway)
gem "sendgrid-actionmailer"

# Solid backend (Rails 8 default for cache, queue, cable)
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "letter_opener"
  gem "letter_opener_web"
end
