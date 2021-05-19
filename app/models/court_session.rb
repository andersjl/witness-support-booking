# === Validation
#
# <tt>court</tt>, <tt>date</tt>, <tt>start</tt>, and <tt>need</tt> must all be
# present.
#
# <tt>date</tt>::   must not be on a weekend.
# <tt>start</tt>::  must be an integer less than the seconds in 24 hours, and
#                   must be unique within the court and date.  
# <tt>need</tt>::   must be less than <tt>PARALLEL_SESSIONS_MAX</tt>, defined
#                   in <tt>config/initializers/site_ruby.rb</tt>.
#
# === Cascading
#
# It <tt>delete</tt>s dependent <tt>bookings</tt> and
# <tt>cancelled_bookings</tt> rather than <tt>destroy</tt>ing them.  For
# <tt>bookings</tt>, this is because <tt>booking.destroy</tt> may create an
# infinite loop if this object has no <tt>reason_to_exist?</tt>.  For
# <tt>cancelled_bookings</tt>, there is really nothing to <tt>destroy</tt>.
class CourtSession < ActiveRecord::Base

  validates :court, presence: true
  validates :date,  presence: true
  validates_each :date do |record, attr, val|
    next unless val
    if val.cwday > 5
      record.errors.add(
        attr,
        I18n.t(
          "court_day.error.weekend",
          date: record.date,
          dow: t( "date.day_names")[ record.date.cwday % 7],
        ),
      )
    end
  end
  validates :start,
    presence:     true,
    numericality: { only_integer:             true,
                    greater_than_or_equal_to: 0,
                    less_than:                24 * 60 * 60},
    uniqueness:   { scope: [ :date, :court_id],
                    message: I18n.t( "court_session.error.start_taken")}
  validates :need, inclusion: { in: 0 .. PARALLEL_SESSIONS_MAX}
# If a session has need == 0 but some booking and is saved by the Database
# model, this validation generates an unwanted error when the saved XML is
# read back again.
  validate  :error_unless_reason_to_exist

  default_scope -> { order( "date ASC, start ASC")}

  belongs_to :court
  has_many :bookings, dependent: :delete_all
  has_many :cancelled_bookings, dependent: :delete_all

  def inspect
    "|#{ court && court.name}|#{ start_time.iso8601}|#{ need}|"
  end

  def start_time
    date && start && (date.in_time_zone + start)
  end

  def fully_booked?; bookings.count >= need end
  def overbooked?; bookings.count > need end
  def booked?; bookings.count > 0 end
  def unbooked?; !booked end
  def needed; need - bookings.count end

  def late_cancels
    if expired? || fully_booked?
      [ ]
    else
      cancelled_bookings.select{ |cancelled| cancelled.late?}
    end
  end

  def reason_to_exist?; need > 0 || !bookings.empty? end
  def expired?; start_time + ALLOW_LATE_BOOKING < Time.current end

  def error_unless_reason_to_exist
    return unless need
    unless reason_to_exist?
      errors.add(
        :need,
        I18n.t( "court_session.error.no_reason_to_exist", session: inspect)
      )
    end
  end
  private :error_unless_reason_to_exist
end

