# === Cascading
#
# You cannot destroy a court that has users.
#
# Court sessions and court day notes, however, are destroyed with the court.
class Court < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  default_scope order: "name"
  has_many :court_sessions, dependent: :destroy
  has_many :court_day_notes, dependent: :destroy
  has_many :users, dependent: :restrict

  def inspect
    "|#{ name}|#{ link}|"
  end
end
