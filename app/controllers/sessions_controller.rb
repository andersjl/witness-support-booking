class SessionsController < ApplicationController

  def new
  end

  def create
    user = User.find_by_email( params[ :session][ :email].downcase)
    if user && user.authenticate( params[ :session][ :password])
      log_in user
      redirect_to court_days_path
    else
      flash.now[ :error] = 'Ogiltig kombination av e-post och lösenord'
      render "new"
    end
  end

  def destroy
    log_out
    redirect_to root_url
  end

end

