class Booking < ActiveRecord::Base

  attr_accessible :court_day_id, :session

  validates :user_id, presence: true
  validates :court_day_id, presence: true
  validates :session, presence: true,
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
      errors[ :base] << I18n.t( "booking.full",
                                court_day: court_day.inspect,
                                session: I18n.t( "booking.#{ session}.short"))
    end
  end

  def within_one_court
    return unless user && court_day  # handled by other validations
    if user.court != court_day.court
      errors[ :base] << I18n.t( "booking.court_mismatch",
                             court_day: court_day.inspect, user: user.inspect)
    end
  end
end
