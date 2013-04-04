class SessionsController < ApplicationController

  class Session
    attr_reader :court_id, :email
    def initialize( court_id)
      @court_id = court_id
    end
  end

  def new
    @courts = Court.all
    @session = Session.new cookies[ :_witness_support_booking_court_id]
  end

  def create
    user = User.find_by_court_id_and_email(
      params[ :session][ :court_id], params[ :session][ :email].downcase)
    if user && master?
      spoof user
      redirect_to court_days_path
    elsif user && user.authenticate( params[ :session][ :password])
      log_in user
      redirect_to court_days_path
    else
      flash[ :error] = t( "sessions.create.error")
      redirect_to log_in_path
    end
  end

  def destroy
    if spoofing
      spoof nil
      redirect_to users_path
    else
      log_out
      redirect_to root_path
    end
  end

end

