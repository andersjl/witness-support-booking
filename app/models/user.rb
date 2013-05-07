class User < ActiveRecord::Base
include Massign

  has_secure_password

  before_save{ |user| user.email = email.downcase}
  before_save :create_remember_token

  validates :court, presence: true
  validates :email, presence: true,
                    uniqueness: { scope: :court_id, case_sensitive: false,
                                  message: I18n.t( "user.error.email_taken")}
  validates :name, presence: true
  validates :password, presence: true, length: { minimum: 6}
  validates :password_confirmation, presence: true
  validates :role, presence: true, inclusion: { in: USER_ROLES}

  belongs_to :court
  has_many :bookings, dependent: :destroy

  def inspect; "|#{ court && court.name}|#{ name}|#{ email}|#{ role}|" end

  def admin?( court = nil)
    role == "master" || (role == "admin" && (!court || self.court == court))
  end

  def master?; role == "master" end
  def enabled?; role != "disabled" end

  def booked?( court_session)
    bookings.find_by_court_session_id court_session.id
  end

  def self.order_by_role_and_name( court)
    where( "court_id = ?", court.id).sort do |u1, u2|
      if u1.role == u2.role
        u1.name <=> u2.name
      else
        u1.role_to_order <=> u2.role_to_order
      end
    end
  end

  def role_to_order; USER_ROLES.index role end
  def self.valid_role?( role); USER_ROLES.include? role end

  def self.disabled_count( court = nil)
    if court
      where( "court_id = ? and role = ?", court, "disabled").count
    else
      where( "role = ?", "disabled").count
    end
  end

  def create_remember_token; self.remember_token = SecureRandom.hex end
  private :create_remember_token
end

