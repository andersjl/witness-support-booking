
class CourtDay < ActiveRecord::Base

  attr_accessible :afternoon, :date, :morning, :notes
  validates :date, :presence => { :message => "Datum saknas"},
                   :uniqueness => { :message => "Datumet är redan använt"}
  validates :morning, :inclusion => { :in => 0 .. PARALLEL_SESSIONS_MAX}
  validates :afternoon, :inclusion => { :in => 0 .. PARALLEL_SESSIONS_MAX}
  validate :there_must_be_something_to_do
  default_scope :order => "court_days.date"

  def there_must_be_something_to_do
    errors[ :base] << "Arbetsuppgifter saknas den #{ date}" unless
      (morning && morning > 0) || (afternoon && afternoon > 0) ||
        !notes.blank?
  end
end

