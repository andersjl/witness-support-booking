class CourtDaysController < ApplicationController
extend Authorization

  authorize :index, [ "normal", "admin", "master"]

  # select and serve one <tt>CourtDay.page</tt>
  def index
    if params[ :start_date]
      chosen_date = Date.parse( params[ :start_date])
      case params[ :commit]
      when VALUE_LAST_WEEK then chosen_date -= 7
      when VALUE_NEXT_WEEK then chosen_date += 7
      end
      session[ :start_date] = CourtDay.monday( chosen_date).iso8601
    end
    collect_court_days( current_user.court)
  end
end

