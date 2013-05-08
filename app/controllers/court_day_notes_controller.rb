class CourtDayNotesController < ApplicationController
extend Authorization

  authorize [ :create, :update], [ "admin", "master"] do |params, user|
    user.master? || user.court.id == params[ :court_day_note][ :court_id].to_i
  end

  def create
    court_day_note = CourtDayNote.new
    court_day_note.massign params[ :court_day_note], :court_id, :date, :text
    if !court_day_note.text.blank? && !court_day_note.save
      @model_with_errors = court_day_note
    end
    back_to_court_days
  end

  def update
    court_day_note = CourtDayNote.find params[ :id]
    if court_day_note
      court_day_note.massign params[ :court_day_note], :text
      if court_day_note.text.blank?
        court_day_note.destroy
      elsif !court_day_note.save
        @model_with_errors = court_day_note
      end
    end
    back_to_court_days
  end
end

