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

  def self.purge_old
    today = Date.current
    ((count + 9) / 10).times do |i|
      cancelled = all.sample
      if cancelled &&
          (today - cancelled.court_session.date) > BOOKING_DAYS_AHEAD_MAX
        cancelled.destroy
      end
    end
  end
end

