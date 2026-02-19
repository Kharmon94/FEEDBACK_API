require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  # config.public_file_server.enabled = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  config.active_storage.service = ENV["AWS_BUCKET"].present? ? :amazon : :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  config.assume_ssl = true
  config.force_ssl = true
  config.silence_healthcheck_path = "/up"

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Info include generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use Solid Cache (no Redis required). Unset REDIS_URL on Railway if set.
  config.cache_store = :solid_cache_store
  # Use :inline so emails send during the request. No Solid Queue tables or worker needed.
  # To use Solid Queue: run `rails solid_queue:install`, add queue DB config, run migrations, and run `bin/jobs`.
  config.active_job.queue_adapter = :inline

  config.action_mailer.perform_caching = false

  host = begin
    u = URI.parse(ENV["API_ORIGIN"].presence || ENV["FRONTEND_ORIGIN"].presence || "https://feedback-page.com")
    u.host
  rescue
    "feedback-page.com"
  end
  config.action_mailer.default_url_options = { host: host, protocol: "https" }

  if ENV["SENDGRID_SECRET"].present?
    config.action_mailer.delivery_method = :sendgrid_actionmailer
    config.action_mailer.sendgrid_actionmailer_settings = {
      api_key: ENV["SENDGRID_SECRET"],
      raise_delivery_errors: true
    }
    config.action_mailer.raise_delivery_errors = true
    config.after_initialize do
      from = ENV["MAILER_FROM"].presence || (AdminSetting.instance.support_email rescue nil)
      Rails.logger.info "[ActionMailer] Production emails enabled (SendGrid API), from: #{from}"
    end
  else
    config.action_mailer.delivery_method = :test
    config.after_initialize do
      Rails.logger.warn "[ActionMailer] SENDGRID_SECRET not set — emails will NOT be delivered (using :test). Set SENDGRID_SECRET in Railway to send real emails."
    end
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
