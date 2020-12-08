class ApplicationController < ActionController::Base
  before_action :log_info, if: -> { Rails.env.development? }

  def log_info
    Rails.logger.info("User identifiter: #{session[:session_id]}. Token: #{session[:user_token]}")
  end

  EXCEPTIONS = [
    UserDatastoreAdapter::DatastoreTimeoutError,
    UserDatastoreAdapter::DatastoreClientError
  ]
  rescue_from(*EXCEPTIONS) do |exception|
    render file: 'public/500.html', status: 500
  end
  layout 'metadata_presenter/application'

  def service
    @service ||= Rails.configuration.service
  end
  helper_method :service

  def save_user_data
    UserData.new(session).save(params.permit(answers: {})[:answers] || {})
  end

  def load_user_data
    UserData.new(session).load_data
  end
end
