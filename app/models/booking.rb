class Booking < ActiveRecord::Base

  validates :user_id, presence: true
  validates :court_session_id, presence: true
  validate :not_overbooked, :within_one_court

  after_destroy :destroy_session_without_reason_to_exist

  belongs_to :user
  belongs_to :court_session

  def inspect
    "|#{ user && user.court && user.court.name}|#{ user && user.email}|#{
               court_session && court_session.start_time.iso8601}|"
  end

  def expired?; court_session.expired? end

  def not_overbooked
    return unless court_session  # handled by other validation
    if court_session.bookings.count >= court_session.need
      errors[ :base] << I18n.t( "booking.error.full",
                                court_session: court_session.inspect)
    end
  end

  def within_one_court
    return unless user && court_session  # handled by other validations
    if user.court != court_session.court
      errors[ :base] << I18n.t( "booking.error.court_mismatch",
                     user: user.inspect, court_session: court_session.inspect)
    end
  end
  
  def destroy_session_without_reason_to_exist
    court_session.destroy if court_session && !court_session.reason_to_exist?
  end
end

