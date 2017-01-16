class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :validate_authentiq_session!
  protect_from_forgery with: :exception

  def validate_authentiq_session!
    return unless signed_in? && session[:service_tickets]

    valid = session[:service_tickets].all? do |provider, ticket|
      Rails.cache.read("omnivise:#{provider}:#{ticket}").present?
    end

    unless valid
      session[:service_tickets] = nil
      sign_out current_user
      redirect_to new_user_session_path
    end
  end

end
