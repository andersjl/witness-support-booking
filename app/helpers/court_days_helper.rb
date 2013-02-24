
module CourtDaysHelper

  def offset_n_span_to_class( offset, span)
    result = ""
    result += "offset#{ offset} " if offset.is_a?( Numeric) && offset > 0
    result += "span#{ span}"
  end

  def back_to_court_days
    collect_court_days
    render "court_days/index"
  end

  def collect_court_days
    session[ :start_date] ||= CourtDay.monday( Date.today).to_s
    @start_date = session[ :start_date]
    @court_days = CourtDay.page( Date.parse( session[ :start_date]))
  end
end

