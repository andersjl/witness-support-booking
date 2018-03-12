
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
  # start_date is the first day to include. Only weekdays are included.
  #
  # Currently recognized options:
  #   :end_date    Last day to include, default start_date + 7 * :weeks - 1
  #   :start_tods  Times of day when the sessions start, default
  #                START_TIMES_OF_DAY_DEFAULT
  #   :weeks       The number of weeks to show when no end_date, ignored if
  #                end_date, default WEEKS_P_PAGE
  def self.page( court, start_date, options = {})
    weeks = options[ :weeks] || WEEKS_P_PAGE
    end_date = options[ :end_date]
    if end_date
      end_date += 1
    else
      end_date = start_date + 7 * weeks
    end
    start_tods = options[ :start_tods] || START_TIMES_OF_DAY_DEFAULT
    dates = (end_date - start_date).to_i.times.reduce( []) do |result, n|
        date = start_date + n
        result << date if date.cwday <= 5
        result
      end
    @@page = dates.collect do |date|
        new( {
            court:    court,
            date:     date,
            sessions: start_tods.collect do |start_tod|
                CourtSession.find_by_date_and_court_id_and_start(
                    date, court, start_tod
                  ) ||
                CourtSession.new(
                    court: court, date: date, start: start_tod, need: 0
                  )
              end,
            note: CourtDayNote.find_by_date_and_court_id( date, court) ||
              CourtDayNote.new( court: court, date: date)
          }
        )
      end
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

