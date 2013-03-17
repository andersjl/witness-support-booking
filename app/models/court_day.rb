
class CourtDay < ActiveRecord::Base

  attr_accessible :afternoon, :court, :date, :morning, :notes
  validates :court, :presence => { :message => "Domstol saknas"}
  validates :date,
            :presence => { :message => "Datum saknas"},
            :uniqueness =>
            { :scope => :court_id,
              :message => "Datumet är redan använt för denna domstol"}
  validates :morning, :inclusion => { :in => 0 .. PARALLEL_SESSIONS_MAX}
  validates :afternoon, :inclusion => { :in => 0 .. PARALLEL_SESSIONS_MAX}
  validate :never_on_weekends
  validate :there_must_be_something_to_do

  default_scope :order => "court_days.date"

  belongs_to :court
  has_many :bookings, :dependent => :destroy

  def inspect
    "##{ court && court.name}##{ date.to_s}##{ morning}##{ afternoon}#"
  end

  def morning_bookings
    bookings.where "session = 0"
  end

  def afternoon_bookings
    bookings.where "session = 1"
  end

  def self.page( court, first_monday)
    defined_days =
      where [ "court_id = ? and date >= ? and date < ?",
              court.id, first_monday, first_monday + 7 * WEEKS_P_PAGE]
    (5 * WEEKS_P_PAGE).times.collect do |n|
      weeks, days = n.divmod 5
      date = first_monday + 7 * weeks + days
      if defined_days.first && defined_days.first.date == date
        defined_days.shift
      else
        new :date => date, :morning => 0, :afternoon => 0
      end
    end
  end

  def self.monday( date)
    date = ensure_weekday( date)
    date - (date.cwday - 1)
  end

  def self.ensure_weekday( date)
    case date.cwday
    when 6 then date += 2
    when 7 then date += 1
    else        date
    end
  end

  def self.session_sv( session)
    session == :morning ? "fm" : "em"
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
end

