class Snapshot < ActiveRecord::Base
  validates :all_data, presence: true
  def inspect; "|Snapshot #{ created_at}|" end
end

