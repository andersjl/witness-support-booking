class Booking < ActiveRecord::Base

  attr_accessible :court_day_id, :session

  validates :user_id,
            :presence  => { :message => "Användar-ID saknas"}
  validates :court_day_id,
            :presence  => { :message => "Rättegångsdag saknas"}
  validates :session,
            :presence  => { :message => "Val för/eftermiddag saknas"},
            :inclusion => { :in => [ :morning, :afternoon]}
  validate :not_overbooked, :within_one_court

  belongs_to :user
  belongs_to :court_day

  def inspect
    "##{ user && user.court && user.court.name}##{ user && user.email
      }##{ court_day && court_day.date.to_s}##{ session}#"
  end

  def session
    lambda{ |s| s && [ :morning, :afternoon][ s]
          }.call( read_attribute :session)
  end

  def session=( s)
    write_attribute :session, self.class.session_to_attribute( s)
  end

  def self.session_to_attribute( s)
    case s; when :morning then 0; when :afternoon then 1 end
  end

  def not_overbooked
    return unless court_day && session  # handled by other validations
    booked = court_day.send( "#{ session}_bookings").count
    if booked >= court_day.send( session)
      errors[ :base] <<
        "#{ court_day.inspect} är fullbokad #{ CourtDay.session_sv session}"
    end
  end

  def within_one_court
    return unless user && court_day  # handled by other validations
    if user.court != court_day.court
      errors[ :base] <<
        "#{ court_day.inspect} och #{ user.inspect} tillhör olika domstolar"
    end
  end
end
