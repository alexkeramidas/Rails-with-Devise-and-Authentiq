class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :validate_authentiq_session!
  protect_from_forgery with: :exception

  def validate_authentiq_session!
    return unless signed_in? && session[:authentiq_tickets]

    valid = session[:authentiq_tickets].all? do |provider, ticket|
      Rails.cache.read("application:#{provider}:#{ticket}").present?
    end

    unless valid
      session[:authentiq_tickets] = nil
      sign_out current_user
      redirect_to new_user_session_path
    end
  end

end
