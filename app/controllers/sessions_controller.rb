class SessionsController < ApplicationController

  def new
    @courts = Court.all
  end

  def create
    user = User.find_by_court_id_and_email(
      params[ :session][ :court_id], params[ :session][ :email].downcase)
    if user && user.authenticate( params[ :session][ :password])
      log_in user
      redirect_to court_days_path
    else
      flash[ :error] = "Ogiltig kombination av domstol, e-post och lösenord"
      redirect_to log_in_path
    end
  end

  def destroy
    log_out
    redirect_to root_path
  end

end

