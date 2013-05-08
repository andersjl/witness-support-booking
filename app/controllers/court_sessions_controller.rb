class CourtSessionsController < ApplicationController
extend Authorization

  authorize [ :create, :update], [ "admin", "master"] do |params, user|
    user.master? || user.court.id == params[ :court_session][ :court_id].to_i
  end

  def create
    court_session = CourtSession.new
    court_session.massign params[ :court_session],
                          :court_id, :date, :start, :need
    if court_session.reason_to_exist? && !court_session.save
      @model_with_errors = court_session
    end
    back_to_court_days
  end

  def update
    court_session = CourtSession.find params[ :id]
    if court_session
      court_session.massign params[ :court_session], :need
      if !court_session.reason_to_exist?
        court_session.destroy
      elsif !court_session.save
        @model_with_errors = court_session
      end
    end
    back_to_court_days
  end
end

