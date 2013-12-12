
module CourtDaysHelper

  def back_to_court_days( court = nil)
    collect_court_days( court || current_user.court)
    render "court_days/index"
  end

  # collects data for the <tt>court_days/index</tt> page
  def collect_court_days( court)
    session[ :start_date] ||= CourtDay.monday( Date.current).iso8601
    @start_date = session[ :start_date]
    @disabled_count = admin? ? User.disabled_count( !master? && court) : 0
    @court_days = CourtDay.page court, Date.parse( session[ :start_date])
  end
end

