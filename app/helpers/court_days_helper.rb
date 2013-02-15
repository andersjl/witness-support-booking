
module CourtDaysHelper

  def offset_n_span_to_class( offset, span)
    result = ""
    result += "offset#{ offset} " if offset.is_a?( Numeric) && offset > 0
    result += "span#{ span}"
  end
end

def back_to_court_days
# if Rails.env.development?
    collect_court_days
    render "court_days/index"
# else
#   redirect_to court_days_path
# end
end

def collect_court_days
  begin
    chosen_date = Date.parse( params[ :start_date])
  rescue
    chosen_date = Date.today + 2
  end
  case params[ :commit]
  when VALUE_LAST_WEEK then chosen_date -= 7
  when VALUE_NEXT_WEEK then chosen_date += 7
  end
  @start_date = chosen_date - (chosen_date.cwday - 1)  # Mon = 0, Sun = 6
  defined_days = CourtDay.find :all,
                               :conditions =>
                                 [ "date >= ? and date < ?",
                                   @start_date,
                                   @start_date +  7 * WEEKS_P_PAGE]
  @court_days = (5 * WEEKS_P_PAGE).times.collect do |n|
    weeks, days = n.divmod 5
    date = @start_date + 7 * weeks + days
    if defined_days.first && defined_days.first.date == date
      defined_days.shift
    else
      CourtDay.new :date => date, :morning => 0, :afternoon => 0
    end
  end
end

