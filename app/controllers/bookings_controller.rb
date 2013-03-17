class BookingsController < ApplicationController
extend Authorization

  authorize :destroy, "admin"

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

