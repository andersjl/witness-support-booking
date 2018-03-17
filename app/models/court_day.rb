
# Note that this class does NOT inherit <tt>ActiveRecord::Base</tt>.  It is a
# pseudo model mainly used to collect data from the other models to serve the
# <tt>court_days/index</tt> view.
#
# It also contains some business logic that has to do with that view default
# starting on a monday and never showing weekends.
class CourtDay

  attr_reader :court, :date, :sessions, :note

  def initialize( attrs)
    @court    = attrs[ :court]
    @date     = attrs[ :date]
    @sessions = attrs[ :sessions]
    @note     = attrs[ :note]
  end

  def inspect
    "|#{ court.name}|#{ sessions.collect{ |s|
                     "#{ s.start_time.iso8601 }|#{ s.need}|"}}|#{ note.text}|"
  end

  # Collect objects for an index page.
  #
  # mode is one of
  #   :cancelled    Cancelled from start_date up to options[ :end_date]
  #   :underbooked  Underbooked from start_date up to options[ :end_date]
  #   :weeks        WEEKS_P_PAGE weeks without filtering
  #
  # start_date is the first day to include. Only weekdays are included.
  #
  # Currently recognized options:
  #   :end_date    Last day to include, default start_date + 7 * :weeks - 1
  #   :start_tods  Times of day when the sessions start, default
  #                START_TIMES_OF_DAY_DEFAULT
  #   :weeks       The number of weeks to show when no end_date, ignored if
  #                end_date, default WEEKS_P_PAGE
  #
  # An optional block is called once for mode :cancelled and :underbooked with
  #   mode   The mode
  #   total  The total number of cancelled / underbooked sessions
  #   extra  The number of late cancels    / sessions with no booking
  #
  def self.page( court, mode, start_date, options = {})
    weeks = options[ :weeks] || WEEKS_P_PAGE
    end_date = options[ :end_date]
    if end_date
      end_date += 1
    else
      end_date = start_date + 7 * weeks
    end
    start_tods = options[ :start_tods] || START_TIMES_OF_DAY_DEFAULT
    count = extra = 0
    @@page = (end_date - start_date).to_i.times.reduce( []) do |result, n|
        date = start_date + n
        next result if date.cwday > 5
        next result if :weeks != mode && date >= Date.today
        include_day = false
        sessions = start_tods.collect do |start_tod|
          session = CourtSession.find_by_date_and_court_id_and_start(
              date, court, start_tod
            ) ||
            CourtSession.new(
              court: court, date: date, start: start_tod, need: 0
            )
          case mode
          when :cancelled
            session.cancelled_bookings.each do |cb|
              count       += 1
              include_day  = true
              extra       += 1 if cb.late?
            end
          when :underbooked
            booked      = session.bookings.count
            underbooked = session.need - booked
            if 0 < underbooked
              count += underbooked
              extra += 1 if 0 == booked
              include_day  = true
            end
          when :weeks
            include_day = true
          end
          session
        end
        next result unless include_day
        result << new( {
              court:    court,
              date:     date,
              sessions: sessions,
              note: CourtDayNote.find_by_date_and_court_id( date, court) ||
                CourtDayNote.new( court: court, date: date)
            }
          )
      end
    yield mode, count, extra if :weeks != mode
    @@page
  end

  # presently only used for testing
  def self.find_on_present_page( date); @@page.find{ |cd| cd.date == date} end

  # Mon - Fri:  this Monday, Sat - Sun: next Monday
  def self.monday( date)
    date = date.to_date
    date = ensure_weekday( date)
    date - (date.cwday - 1)
  end

  def self.add_weekdays( date, days)
    start = ensure_weekday( date)
    offs = start.cwday - 1
    # ensure that add_weekdays( <sat or sun>, 1) = <mon>
    days -= 1 if start > date && days > 0
    start - offs + lambda{ |w, d| 7 * w + d}.call( *((offs + days).divmod 5))
  end

  def self.ensure_weekday( date)
    date = date.to_date
    case date.cwday
    when 6 then date += 2
    when 7 then date += 1
    else        date
    end
  end
end

