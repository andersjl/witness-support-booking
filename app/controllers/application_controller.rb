
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include UserSessionsUtils
  include CourtDaysUtils

  # Handles a parameter that is also stored as a string in session.
  #
  # The returned value is converted to a symbol if no block given.
  #
  # An optional block converts the value.  If the block return value is an
  # Array, it is a pair [ <value to use>, <string to store in session>]. If
  # not, it is the value to use.  (So you cannot store an Array this way!)
  #
  # If there is no string to store in the session, the session key is deleted
  # from the session.
  #
  # options
  #   :no_params       truthy => only look for a value in session
  #   :session_key     default param
  #   :session_prefix  String prepended to param
  #   :default         value if not found in params or session
  # If no block, a value in params is converted to a symbol.
  def persistent_param( param, options)
    sess_key =
      ( options[ :session_key] ||
        ( options[ :session_prefix] &&
            ( options[ :session_prefix] + "_" + param.to_s)
        ) || param
      ).intern
    value =
      ( ( ! options[ :no_params] && params[ param]) ||
        session[ sess_key] ||
        options[ :default]
      ).to_s
    value = nil if 0 == value.strip.length
    if value
      if block_given?
        converted = yield( value)
        converted, value = converted if converted.is_a? Array
      else
        converted = value.intern
      end
      session[ sess_key] = value
    else
      session.delete( sess_key)
    end
    converted
  end

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

