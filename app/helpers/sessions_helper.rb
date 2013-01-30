
module SessionsHelper

  def log_in( user)
    cookies.permanent[ :remember_token] = user.remember_token
    self.current_user = user
  end

  def log_out
    self.current_user = nil
    cookies.delete( :remember_token)
  # forget_return_to
  end

  def logged_in?
    !current_user.nil?
  end

  def current_user=( user)
    @current_user = user
  end

  def current_user
    @current_user ||= User.find_by_remember_token( cookies[ :remember_token])
  end

  def current_user?( user)
    user == current_user
  end

=begin
  def redirect_back_or( default)
    redirect_to( return_to || default)
    forget_return_to
  end

  def return_to
    session[ :return_to]
  end

  def store_return_to
    session[ :return_to] = request.url
  end

  def forget_return_to
    session.delete( :return_to)
  end
=end

  def logged_in_user
    redirect_to log_in_url, :notice => "Logga in först" unless logged_in?
  end

  def correct_user
    redirect_to( root_path) unless current_user?( User.find( params[ :id]))
  end
  
  def admin_user
    redirect_to( root_path) unless current_user.admin?
  end
end

