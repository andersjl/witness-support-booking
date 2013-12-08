require 'spec_helper'

describe Database do
  before{ @database = Database.new all_data: nil}
  subject{ @database}
  it{ should respond_to( :all_data)}
  it{ should respond_to( :oldest_date)}
  it{ should be_valid}
  context "#row_count" do
  include DatabaseRows
    before do
      u = create_test_user
      s1, s2 = create_test_court_session count: 2
      n = create_test_court_day_note
      b1 = Booking.create! user: u, court_session: s1
      b2 = Booking.create! user: u, court_session: s2
      b1.destroy_and_log
      init_row_counts
    end
    it{ subject.row_count( DatabaseRows::DISTANT_PAST).
          should == count_not_older_than( DatabaseRows::DISTANT_PAST)}
    it{ subject.row_count( @mid_date).
          should == count_not_older_than( @mid_date)}
    it{ subject.row_count( DatabaseRows::DISTANT_FUTURE).
          should == count_not_older_than( DatabaseRows::DISTANT_FUTURE)}
  end
end

