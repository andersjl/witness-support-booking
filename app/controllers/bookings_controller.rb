class BookingsController < ApplicationController
extend Authorization

  authorize :destroy, [ "admin", "master"] do |id, user|
    Booking.find( id).user.court == user.court
  end

  def destroy
    destroyed = Booking.find( params[ :id])
    user = destroyed.user.name
    date = destroyed.court_day.date
    session = CourtDay.session_sv destroyed.session
    destroyed.destroy
    flash[ :success] = "#{ user} avbokad #{ date} #{ session}"
    redirect_to court_days_path
  end
end

