class UserSessionsController < ApplicationController

  before_action :cookies_required, :only => :new

  class UserSession
    attr_reader :court_id, :email
    def initialize( court_id)
      @court_id = court_id
    end
  end

  def new
    @courts = Court.all
    @user_session =
      UserSession.new cookies[ :_witness_support_booking_court_id]
  end

  def create
    user = User.find_by_email_and_court_id(
                  params[ :user_session][ :email].downcase,
                  params[ :user_session][ :court_id])
    if user && master? && !user.master?
      spoof user
      redirect_to court_days_path
    elsif user && user.authenticate( params[ :user_session][ :password])
      log_in user
      redirect_to court_days_path
    else
      flash[ :error] = t( "user_sessions.create.error")
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

