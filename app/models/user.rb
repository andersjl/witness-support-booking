class User < ActiveRecord::Base

  attr_accessible :email, :name, :password, :password_confirmation
  has_secure_password

  before_save { |user| user.email = email.downcase}
  before_save :create_remember_token

  validates :email, 
            :presence   => { :message => "Mejladress saknas"},
            :uniqueness => { :case_sensitive => false,
                             :message => "Adressen är redan använd"}
  validates :name,
            :presence   => { :message => "Namn saknas"}
  validates :password,
            :presence   => { :message => "Lösenord saknas"},
            :length     => { :minimum => 6,
                             :message => "Lösenord minst 6 tecken"}
  validates :password_confirmation,
            :presence   => { :message => "Bekräftelse av lösenord saknas"}

  has_many :bookings, :dependent => :destroy
  has_many :court_days, :through => :bookings

  def book!( court_day, session)
    bookings.create! :court_day_id => court_day.id, :session => session
  end

  def booked?( court_day, session)
    bookings.find_by_court_day_id_and_session(
      court_day.id, Booking.session_to_attribute( session))
  end

  def create_remember_token
    self.remember_token = SecureRandom.hex
  end
  private :create_remember_token

end

