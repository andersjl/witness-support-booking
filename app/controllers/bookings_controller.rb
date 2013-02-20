class BookingsController < ApplicationController

  before_filter :logged_in_user
  before_filter :enabled_user
  before_filter :admin_user

  def destroy
    destroyed = Booking.find( params[ :id])
    user = destroyed.user.name
    date = destroyed.court_day.date
    session = destroyed.session == :morning ? "fm" : "em"
    destroyed.destroy
    flash[ :success] = "#{ user} avbokad #{ date} #{ session}"
    redirect_to court_days_path
  end
end

