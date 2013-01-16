class User < ActiveRecord::Base

  attr_accessible :email, :name, :password, :password_confirmation
  has_secure_password

  before_save { |user| user.email = email.downcase}
  before_save :create_remember_token

  validates :email, :presence => true,
                    :uniqueness => { :case_sensitive => false}
  validates :name, :presence => true
  validates :password, :presence => true, :length => { :minimum => 6}
  validates :password_confirmation, :presence => true

  def create_remember_token
    self.remember_token = SecureRandom.hex
  end
  private :create_remember_token

end

