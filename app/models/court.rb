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
