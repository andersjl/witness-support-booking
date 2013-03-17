
module SessionsHelper

  def current_user
    @current_user ||= User.find_by_remember_token( session[ :remember_token])
  end

  def current_user?( user)
    user == current_user
  end

  def log_in( user)
    reset_session
    session[ :remember_token] = user.remember_token
    cookies.permanent[ :court_id] = user.court.id
    @current_user = user
  end

  def log_out
    @current_user = nil
    session.delete( :remember_token)
  end

  def logged_in?
    !current_user.nil?
  end
  
  def enabled?
    current_user && current_user.enabled?
  end

  def admin?
    current_user && current_user.admin?
  end

  def master?
    current_user && current_user.master?
  end
end

