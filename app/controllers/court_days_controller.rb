class CourtDaysController < ApplicationController
extend Authorization

  authorize :index, [ "normal", "admin", "master"]

  # select and serve one <tt>CourtDay.page</tt>
  def index
    collect_court_days( current_user.court)
  end
end

