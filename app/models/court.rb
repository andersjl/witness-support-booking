class Court < ActiveRecord::Base
  attr_accessible :name, :link
  validates :name, presence: true, uniqueness: true
  default_scope :order => "courts.name"
  has_many :court_days, :dependent => :destroy
  has_many :users, :dependent => :restrict

  def inspect
    "##{ name}##{ link}#"
  end
end
