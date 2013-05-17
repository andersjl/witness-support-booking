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
    booking.user_id          = params[ :booking][ :user_id]
    booking.court_session_id = params[ :booking][ :court_session_id]
    @model_with_errors = booking unless booking.save
    back_to_court_days
  end

  def destroy
    cancelled = Booking.find params[ :id]
    if cancelled
      user = cancelled.user
      if current_user? user
        session = cancelled.court_session
        if cancelled.destroy_and_log.late? && !session.fully_booked?
          flash[ :error] = t( "booking.cancel.late")
        end
      else
        flash[ :success] =
          t( "booking.cancelled", user: user.name,
             date: cancelled.court_session.date,
             session: t( "court_session.name#{ cancelled.court_session.start
                                             }.short"))
        cancelled.destroy
      end
    end
    redirect_to court_days_path
  end
end

