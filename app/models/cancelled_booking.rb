# <tt>obsolete?</tt> objects are purged incrementally by a
# <tt>before_save</tt> callback
class CancelledBooking < ActiveRecord::Base

  before_save{ purge_old}
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

  # The use here of the <tt>BOOKING_DAYS_AHEAD_MAX</tt> limit (defined in
  # <tt>config/initializers/site_ruby.rb</tt>) is rather arbitrary
  def obsolete?
    Date.current >
      CourtDay.add_weekdays( court_session.date, BOOKING_DAYS_AHEAD_MAX)
  end

  def purge_old
    ((self.class.count + 9) / 10).times do
      cancelled = self.class.all.sample
      cancelled.destroy if cancelled.obsolete?
    end
  end
  private :purge_old
end
 
