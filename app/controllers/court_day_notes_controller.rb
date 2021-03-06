class CourtDayNotesController < ApplicationController
extend Authorization

  authorize :create, [ "admin", "master"] do |params, user|
    user.master? || user.court_id == params[ :court_day_note][ :court_id].to_i
  end

  authorize :update, [ "admin", "master"] do |params, user|
    # #update does not use params[ :court_day_note][ :court_id]
    user.master? || user.court_id == CourtDayNote.find( params[ :id]).court_id
  end

  def create
    court_day_note = CourtDayNote.new
    court_day_note.court_id = params[ :court_day_note][ :court_id]
    court_day_note.date     = params[ :court_day_note][ :date]
    court_day_note.text     = params[ :court_day_note][ :text]
    if !court_day_note.text.blank? && !court_day_note.save
      @model_with_errors = court_day_note
    end
    back_to_court_days
  end

  def update
    court_day_note = CourtDayNote.find params[ :id]
    if court_day_note
      court_day_note.text = params[ :court_day_note][ :text]
      if court_day_note.text.blank?
        court_day_note.destroy
      elsif !court_day_note.save
        @model_with_errors = court_day_note
      end
    end
    back_to_court_days
  end
end

