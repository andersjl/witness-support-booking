# encoding: UTF-8

class User < ActiveRecord::Base

  class UserModelRoleError < StandardError; end

  attr_accessible :email, :name, :password, :password_confirmation
  has_secure_password

  before_save { |user| user.email = email.downcase}
  before_save :create_remember_token

  validates :court,
            :presence   => { :message => "Domstol saknas"}
  validates :role,
            :presence   => true, :inclusion  => { :in => USER_ROLES}
  validates :email, 
            :presence   => { :message => "Mejladress saknas"},
            :uniqueness => { :scope => :court_id, :case_sensitive => false,
                             :message =>
                             "Mejladressen är redan använd vid denna domstol"}
  validates :name,
            :presence   => { :message => "Namn saknas"}
  validates :password,
            :presence   => { :message => "Lösenord saknas"},
            :length     => { :minimum => 6,
                             :message => "Lösenord minst 6 tecken"}
  validates :password_confirmation,
            :presence   => { :message => "Bekräftelse av lösenord saknas"}

  belongs_to :court
  has_many :bookings, :dependent => :destroy
  has_many :court_days, :through => :bookings

  def inspect
    "##{ court && court.name}##{ name}##{ email}##{ role}#"
  end

  def admin?( court = nil)
    role == "master" || (role == "admin" && (!court || self.court == court))
  end

  def master?
    role == "master"
  end

  def enabled?
    role != "disabled"
  end

  def book!( court_day, session)
    bookings.create! :court_day_id => court_day.id, :session => session
  end

  def booked?( court_day, session)
    bookings.find_by_court_day_id_and_session(
      court_day.id, Booking.session_to_attribute( session))
  end

  def self.order_by_role_and_name( court)
    where( "court_id = ?", court.id).sort do |u1, u2|
      if u1.role == u2.role
        u1.name <=> u2.name
      else
        role_to_order( u1.role) <=> role_to_order( u2.role)
      end
    end
  end

  def self.valid_role?( role)
    USER_ROLES.include? role
  end

  def self.role_to_order( role)
    unless valid_role? role
      raise UserModelRoleError.new( "unknown role \"#{ role}\"")
    end
    USER_ROLES.index role
  end

  def >( other_user)
    self.class.role_to_order( role) >
      self.class.role_to_order( other_user.role)
  end

  def create_remember_token
    self.remember_token = SecureRandom.hex
  end
  private :create_remember_token
end

