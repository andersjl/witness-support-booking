class Booking < ActiveRecord::Base

  attr_accessible :court_day_id, :session

  validates :user_id,
            :presence  => { :message => "Användar-ID saknas"}
  validates :court_day_id,
            :presence  => { :message => "Rättegångsdag saknas"}
  validates :session,
            :presence  => { :message => "Val för/eftermiddag saknas"},
            :inclusion => { :in => [ :morning, :afternoon]}

  belongs_to :user
  belongs_to :court_day

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
end
