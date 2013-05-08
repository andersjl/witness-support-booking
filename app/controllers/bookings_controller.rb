class BookingsController < ApplicationController
extend Authorization

  authorize :create, "normal" do |params, user|
    params[ :booking][ :user_id].to_i == user.id
  end
  authorize :destroy, [ "normal", "admin", "master"] do |params, user|
    booked_user = Booking.find( params[ :id]).user
    booked_user == user || user.master? ||
      (user.admin? && booked_user.court == user.court)
  end

  def create
    booking = Booking.new
    booking.massign params[ :booking], :user_id, :court_session_id
    @model_with_errors = booking unless booking.save
    back_to_court_days
  end

  def destroy
    destroyed = Booking.find params[ :id]
    if destroyed
      user = destroyed.user
      unless current_user? user
        user_name = user.name
        date = destroyed.court_session.date
        session = destroyed.court_session.template
      end
      destroyed.destroy
      unless current_user? user
        flash[ :success] = t( "booking.unbooked",
                              user: user_name, date: date, session: session)
      end
    end
    redirect_to court_days_path
  end
end

