class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def authentiq
    if params['user_id']
      Rails.cache.write("omnivise:#{:authentiq}:#{params['user_id']}", params['user_id'], expires_in: 28800)
      session[:service_tickets] ||= {}
      session[:service_tickets][:authentiq] = params['user_id']
    end
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user != nil
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => :authentiq) if is_navigational_format?
    else
      session["devise.authentiq_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end