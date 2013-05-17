class CancelledBooking < ActiveRecord::Base

  before_save{ |cancelled| CancelledBooking.purge_old}
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

  def obsolete?
    Date.current >
      CourtDay.add_weekdays( court_session.date, BOOKING_DAYS_AHEAD_MAX)
  end

  def self.purge_old
    ((count + 9) / 10).times do |i|
      cancelled = all.sample
      cancelled.destroy if cancelled.obsolete?
    end
  end
end

