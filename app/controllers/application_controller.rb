
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include UserSessionsHelper
  include CourtDaysHelper

  # Detects if cookies are present (only GET requests, not for bots).
  # If cookies are disabled, shows a flash message.
  # Usage:
  # * relevant controllers:
  #   before_action :cookies_required
  # Adapted from
  #   http://code.freudendahl.net/2012/04/ruby-on-rails-cookie-detection/
  # who adapted it from
  #   http://clearcove.ca/2009/09/rails-cookie-detection/
  def cookies_required
    # check if anything needs to be done at all
    if (request && request.request_method != 'GET') ||     # non-GET requests
     # cookies.count > 1 ||  # allow the "turbolinks" cookie "request_method"
       cookies[ :_witness_support_booking_court_id] ||     # probably safer
       cookies[ :_witness_support_booking_cookie_test] ||  # then just count
       is_megatron?( request.env[ "HTTP_USER_AGENT"])      # bot requests
      return true
    end
    # set a flash message on the second call
    if params[ :_witness_support_booking_cookie_test].present?
      logger.warn( "=== cookies are disabled")
      redirect_to cookies_info_path
      return true
    end
    # otherwise set a cookie and redirect to the current URL + parameter
    cookies[ :_witness_support_booking_cookie_test] = Time.now
    redirect_to "#{ request.url}#{ request.url.index( '?') ? '&' : '?'
                  }_witness_support_booking_cookie_test=#{ Time.now.to_i}"
  end
 
  # from: http://gurge.com/blog/2007/01/08/turn-off-rails-sessions-for-robots/
  # added bingbot + a generic bot for new bots
  def is_megatron?(user_agent)
    user_agent =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|bingbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg|bot)\b/i
  end
end

