
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

  def logged_in_user
    redirect_to log_in_url, :notice => "Logga in först" unless logged_in?
  end

  def correct_user
    begin
      params_user = User.find( params[ :id])
      redirect_to( root_path) unless current_user? params_user
    rescue
      redirect_to( root_path)
    end
  end
  
  def admin_user
    redirect_to( root_path) unless current_user.admin?
  end
end

