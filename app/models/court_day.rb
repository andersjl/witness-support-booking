
class CourtDay < ActiveRecord::Base

  attr_accessible :afternoon, :date, :morning, :notes
  validates :date, :presence => { :message => "Datum saknas"},
                   :uniqueness => { :message => "Datumet är redan använt"}
  validates :morning, :inclusion => { :in => 0 .. PARALLEL_SESSIONS_MAX}
  validates :afternoon, :inclusion => { :in => 0 .. PARALLEL_SESSIONS_MAX}
  validate :never_on_weekends
  validate :there_must_be_something_to_do
  default_scope :order => "court_days.date"

  def morning_taken( session = nil)  # stub
    if session
      "NN"
    else
      @morning_taken ||= rand( morning + 1)
    end
  end

  def afternoon_taken( session = nil)  # stub
    if session
      "NN"
    else
      @afternoon_taken ||= rand( afternoon + 1)
    end
  end

  def never_on_weekends
    return unless date  # handled by presence
    case date.cwday
    when 6 then error = "lördag"
    when 7 then error = "söndag"
    end
    errors[ :base] << "#{ date} är en #{ error}" if error
  end

  def there_must_be_something_to_do
    errors[ :base] <<
      "Arbetsuppgifter saknas den #{ date}" unless something_to_do?
  end

  def something_to_do?
    (morning && morning > 0) || (afternoon && afternoon > 0) || !notes.blank?
  end

  def before_save(record)
    record.notes = record.notes.gsub( "\r", " *** ")
  end
end

