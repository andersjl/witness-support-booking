# === Validations
#
# <tt>court</tt>, <tt>email</tt>, <tt>name</tt>, <tt>password</tt>,
# <tt>password_confirmation</tt>, and <tt>role</tt> are all required.
# <tt>email</tt>::     Must be unique within the <tt>court</tt>.
# <tt>password</tt>::  At least six characters.
# <tt>role</tt>::      One of <tt>USER_ROLES</tt>, defined in
#                      <tt>config/initializers/site_config.rb</tt>.
#
# === Cascading
#
# It <tt>destroys</tt>s dependent <tt>bookings</tt>.  This means that
# <tt>CourtSession</tt>s that no longer have any <tt>reason_to_exist?</tt> are
# also destroyed.
#
# <tt>cancelled_bookings</tt> are <tt>deleted</tt>.  There is really nothing
# to <tt>destroy</tt>.
class User < ActiveRecord::Base

  has_secure_password

  validates :court, presence: true
  validates :email, presence: true,
                    uniqueness: { scope: :court_id, case_sensitive: false,
                                  message: I18n.t( "user.error.email_taken")}
  validates :name, presence: true
  validates :password, presence: true, length: { minimum: 6}
  validates :password_confirmation, presence: true
  validates :role, presence: true, inclusion: { in: USER_ROLES}

  before_save{ |user| user.email = email.downcase.gsub( /\s+/, "")}
  before_save :create_remember_token

  belongs_to :court
  has_many :bookings,           dependent: :restrict_with_error
  has_many :cancelled_bookings, dependent: :restrict_with_error
  has_many :court_sessions, through: :bookings

  def inspect; "|#{ court && court.name}|#{ name}|#{ email}|#{ role}|" end

  def admin?( court = nil)
    role == "master" || (role == "admin" && (!court || self.court == court))
  end

  def master?; role == "master" end
  def enabled?; role != "disabled" end

  def booked?( court_session)
    bookings.find_by_court_session_id court_session.id
  end

  def invalidate
    update_columns zombie: true, role: "disabled", password_digest: nil
    # note that the record is no longer valid!
    # we invalidate rather than destroy to keep past bookings
    self.court_sessions =
      court_sessions.where( "date < '#{ Time.now.strftime( "%F")}'")
  end

  def self.order_by_role_and_name( court)
    where( court: court, zombie: false).sort do |u1, u2|
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
      where( court: court, role: "disabled", zombie: false).count
    else
      where( role: "disabled", zombie: false).count
    end
  end

  def create_remember_token; self.remember_token = SecureRandom.hex end
  private :create_remember_token
end

