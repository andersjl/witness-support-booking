
class CourtDay

  attr_reader :court, :date, :sessions, :note

  def initialize( attrs)
    @court = attrs[ :court]
    @date = attrs[ :date]
    @sessions = attrs[ :sessions]
    @note = attrs[ :note]
  end

  def inspect
    "|#{ court.name}|#{ sessions.collect{ |s|
                     "#{ s.start_time.iso8601 }|#{ s.need}|"}}|#{ note.text}|"
  end

  def self.page( court, date_in_first_week, *start_tods)
    start_tods = START_TIMES_OF_DAY_DEFAULT if start_tods.count == 0
    first_monday = monday( date_in_first_week)
    @@page = (5 * WEEKS_P_PAGE).times.collect do |n|
      attrs = { court: court}
      weeks, days = n.divmod 5
      date = first_monday + 7 * weeks + days
      attrs[ :date] = date
      attrs[ :sessions] = start_tods.collect do |start_tod|
        CourtSession.find_by_date_and_court_id_and_start(
                       date, court, start_tod) || CourtSession.new(
                         court: court, date: date, start: start_tod, need: 0)
      end
      attrs[ :note] = CourtDayNote.find_by_date_and_court_id( date, court) ||
                        CourtDayNote.new( court: court, date: date)
      new attrs
    end
  end

  def self.find_on_present_page( date); @@page.find{ |cd| cd.date == date} end

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

