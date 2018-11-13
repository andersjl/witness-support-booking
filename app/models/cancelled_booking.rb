class CancelledBooking < ActiveRecord::Base
include ValidateWithinOneCourt

  validates :user_id, presence: true
  validates :court_session_id, presence: true
  validates :cancelled_at, presence: true
  validate  :within_one_court

  belongs_to :user
  belongs_to :court_session

  def inspect
    "Cancelled #{ cancelled_at.iso8601
                }: |#{ user && user.court && user.court.name
                     }|#{ user && user.email
                        }|#{ court_session && court_session.start_time.iso8601
                           }|"
  end

  def late?
    court_session.date < CourtDay.add_weekdays( cancelled_at.to_date,
                                                 BOOKING_DAYS_AHEAD_MIN)
  end
end
 
