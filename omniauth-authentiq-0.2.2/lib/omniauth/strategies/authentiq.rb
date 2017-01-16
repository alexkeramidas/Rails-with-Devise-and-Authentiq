require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Authentiq < OmniAuth::Strategies::OAuth2
      autoload :BackChannelLogoutRequest, 'omniauth/strategies/oidc/back_channel_logout_request'

      #Set the base URL
      BASE_URL = 'https://test.connect.authentiq.io/'

      # Authentiq strategy name
      option :name, 'authentiq'

      # Build the basic client options (url, authorization url, token url)
      option :client_options, {
          :site => BASE_URL,
          :authorize_url => '/authorize',
          :token_url => '/token'
      }

      # Get options from parameters
      option :authorize_options, [:scope]

      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.

      # Get the user id from raw info
      uid { raw_info['sub'] }

      info do
        {
            :name => (@raw_info['name'] unless @raw_info['name'].nil?),
            :first_name => (@raw_info['given_name'] unless @raw_info['given_name'].nil?),
            :last_name => (@raw_info['family_name'] unless @raw_info['family_name'].nil?),
            :email => (@raw_info['email'] unless @raw_info['email'].nil?),
            :phone => (@raw_info['phone_number'] unless @raw_info['phone_number'].nil?),
            :location => (@raw_info['address'] unless @raw_info['address'].nil?),
            :geolocation => (@raw_info['aq:location'] unless @raw_info['aq:location'].nil?)
        }.reject { |k, v| v.nil? }
      end

      extra do
        {
            :middle_name => (@raw_info['middle_name'] unless @raw_info['middle_name'].nil?),
            :email_verified => (@raw_info['email_verified'] unless @raw_info['email_verified'].nil?),
            :phone_type => (@raw_info['phone_type'] unless @raw_info['phone_type'].nil?),
            :phone_number_verified => (@raw_info['phone_number_verified'] unless @raw_info['phone_number_verified'].nil?),
            :locale => (@raw_info['locale'] unless @raw_info['locale'].nil?),
            :zoneinfo => (@raw_info['zoneinfo'] unless @raw_info['zoneinfo'].nil?)
        }.reject { |k, v| v.nil? }
      end

      def raw_info
        @raw_info ||= access_token.get('/userinfo').parsed
        request.update_param('user_id', @raw_info['sub'])
        @raw_info
      end

      # Over-ride callback_url definition to maintain
      # compatibility with omniauth-oauth2 >= 1.4.0
      #
      # See: https://github.com/intridea/omniauth-oauth2/issues/81
      def callback_url
        # Fixes regression in omniauth-oauth2 v1.4.0 by https://github.com/intridea/omniauth-oauth2/commit/85fdbe117c2a4400d001a6368cc359d88f40abc7
        options[:callback_url] || (full_host + script_name + callback_path)
      end

      # override callback phase to check if this is a logout request
      def callback_phase
        should_sign_out? ? sign_out_phase : super
      end

      def should_sign_out?
        request.post? && request.params.has_key?('logout_token')
      end

      # it indeed is a sign out request so proceed with a sign out if it is enabled in the options
      def sign_out_phase
        if options[:enable_remote_sign_out]
            backchannel_logout_request.new(self, request).call(options)
        end
      end

      private

      def backchannel_logout_request
        BackChannelLogoutRequest
      end

    end
  end
end