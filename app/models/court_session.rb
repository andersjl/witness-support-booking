class CourtSession < ActiveRecord::Base

  validates :court, presence: true
  validates :date,  presence: true
  validates_each :date do |record, attr, val|
    next unless val
    if val.cwday > 5
      record.errors[ attr] <<
        I18n.t( "court_day.error.weekend", date: record.date,
                dow: t( "date.day_names")[ record.date.cwday % 7])
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
  validate  :error_unless_reason_to_exist

  default_scope order: "date, start"

  belongs_to :court
  has_many :bookings, dependent: :delete_all  # booking.destroy creates
                                       # infinite loop unless reason_to_exist?
  has_many :cancelled_bookings, dependent: :delete_all  # nothing to destroy

  def inspect
    "|#{ court && court.name}|#{ start_time.iso8601}|#{ need}|"
  end

  def start_time
    date && start && (date.to_time_in_current_zone + start)
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
  def expired?; start_time < Time.current end

  def error_unless_reason_to_exist
    return unless need
    unless reason_to_exist?
      errors[ :need] << I18n.t( "court_session.error.no_reason_to_exist",
                                session: inspect)
    end
  end
end

