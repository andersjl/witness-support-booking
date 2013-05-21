class CourtSessionsController < ApplicationController
extend Authorization

  authorize :create, [ "admin", "master"] do |params, user|
    user.master? || user.court_id == params[ :court_session][ :court_id].to_i
  end

  authorize :update, [ "admin", "master"] do |params, user|
    # #update does not use params[ :court_session][ :court_id]
    user.master? || user.court_id == CourtSession.find( params[ :id]).court_id
  end

  # silently does nothing at all if the data in <tt>params</tt> gives no
  # <tt>#reason_to_exist?</tt>
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

  # ignores all of <tt>params</tt> except <tt>[ :court_session][ :need]</tt>,
  # silently destroys an existing object if no <tt>#reason_to_exist?</tt>
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

