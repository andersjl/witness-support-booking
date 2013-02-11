class CourtDaysController < ApplicationController

  before_filter :logged_in_user
  before_filter :enabled_user
  before_filter :admin_user, :only => :update

  def index
    collect_court_days
  end

  def update
    @court_day = CourtDay.find_by_date( params[ :id])
    if @court_day
      update_or_destroy
    else
      create
    end
    back_to_court_days
  end

  def update_or_destroy
    updated = params_to_court_day
    if updated.something_to_do?
    # if [ @court_day.morning, @court_day.afternoon, @court_day.notes.blank?
    #    ] != [ updated.morning, updated.afternoon, updated.notes.blank?]
        @court_day.morning = updated.morning
        @court_day.afternoon = updated.afternoon
        @court_day.notes = updated.notes
        @court_day.save
    # end
    else
      @court_day.destroy
      @court_day = nil
    end
  end

  def create
    @court_day = params_to_court_day
    @court_day.save if @court_day.something_to_do?
  end

  # params[ :id] is not the DB id, and there are dates in the field names
  def params_to_court_day
    date = "-#{ params[ :id]}"
    CourtDay.new(
      :date => params[ :id],
      :morning => params[ "morning" + date],
      :afternoon => params[ "afternoon" + date],
      :notes => params[ "notes" + date].blank? ? nil : params[ "notes" + date
                                                             ].strip)
  end

end

