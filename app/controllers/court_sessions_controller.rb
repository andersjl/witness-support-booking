class CourtSessionsController < ApplicationController
extend Authorization

  authorize [ :create, :update], [ "admin", "master"] do |params, user|
    user.master? || user.court.id == params[ :court_session][ :court_id].to_i
  end

  def create
    court_session = CourtSession.new
    court_session.court_id = params[ :court_session][ :court_id]
    court_session.date     = params[ :court_session][ :date]
    court_session.start    = params[ :court_session][ :start]
    court_session.need     = params[ :court_session][ :need]
    if court_session.reason_to_exist? && !court_session.save
      @model_with_errors = court_session
    end
    back_to_court_days
  end

  def update
    court_session = CourtSession.find params[ :id]
    if court_session
      court_session.need = params[ :court_session][ :need]
      if !court_session.reason_to_exist?
        court_session.destroy
      elsif !court_session.save
        @model_with_errors = court_session
      end
    end
    back_to_court_days
  end
end

