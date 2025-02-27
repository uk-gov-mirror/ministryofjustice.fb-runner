require_relative 'boot'
require_relative "../lib/rack_x_robots_tag"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FbRunner
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.middleware.use Rack::XRobotsTag
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end

Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger]
  config.logger =  Logger.new(STDOUT)

  config.before_send = lambda do |event, _hint|
    if event.request && event.request.data
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      event.request.data = filter.filter(event.request.data)
    end
    event
  end
end
