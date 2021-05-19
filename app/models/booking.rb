class Booking < ActiveRecord::Base
include ValidateWithinOneCourt

  validates :user_id, presence: true
  validates :court_session_id, presence: true
  validates :booked_at, presence: true
  validate :not_overbooked, :within_one_court

  before_save :destroy_cancelled_booking
  after_destroy :destroy_session_without_reason_to_exist

  belongs_to :user
  belongs_to :court_session

  def inspect
    "|#{ user && user.court && user.court.name}|#{ user && user.email}|#{
               court_session && court_session.start_time.iso8601}|"
  end

  def expired?
    CourtDay.add_weekdays( court_session.start_time.to_date,
                           BOOKING_DAYS_REMOVABLE) < Date.current
  end

  # creates and returns a CancelledBooking to mirror <tt>self</tt> unless if
  # the destruction destroys the court_session, too, nil is returned.
  def destroy_and_log
    destroy
    court_session.reload
    CancelledBooking.create! court_session: court_session, user: user,
                             cancelled_at: Time.current
  rescue
    nil
  end

  def not_overbooked
    return unless court_session  # handled by other validation
    if court_session.fully_booked?
      errors.add(
        :base,
        I18n.t( "booking.error.full", court_session: court_session.inspect)
      )
    end
  end
  private :not_overbooked

  def destroy_cancelled_booking
    cancelled = CancelledBooking.find_by_court_session_id_and_user_id(
                                   court_session.id, user.id)
    cancelled.destroy if cancelled
  end
  private :destroy_cancelled_booking

  def destroy_session_without_reason_to_exist
    court_session.destroy if court_session && !court_session.reason_to_exist?
  end
  private :destroy_session_without_reason_to_exist
end

