class CourtDayNote < ActiveRecord::Base

  validates :court, presence: true
  validates :date, presence: true,
            uniqueness: { scope: :court_id,
                          message: I18n.t( "court_day_note.error.date_taken")}
  validates_each :date do |record, attr, value|
    next unless value
    if value.cwday > 5
      record.errors.add(
        attr,
        I18n.t(
          "court_day.error.weekend",
          date: value,
          dow: t( "date.day_names")[ value.cwday % 7],
        ),
      )
    end
  end
  validates :text, presence: true

  before_save{ |note| note.text.strip!}

  default_scope -> { order( "date ASC")}

  belongs_to :court

  def inspect
    "|#{ court && court.name}|#{ date.to_s}|#{ text}|"
  end

  def expired?; date < Date.current end
end

