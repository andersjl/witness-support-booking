require 'spec_helper'

describe "Booking model" do

  before do
    @court_day = create_test_court_day :morning => 1, :afternoon => 2
    @user1, @user2, @user3 = create_test_user :count => 3
    @booking = @user1.bookings.build :court_day_id => @court_day.id,
                                     :session => :afternoon
  end

  subject{ @booking}

  it{ should respond_to( :user)}
  it{ should respond_to( :court_day)}
  it{ should respond_to( :session)}
  it{ should be_valid}

  describe "accessible attributes" do

    it "should not allow access to user_id" do
      lambda{ Booking.new( :user_id => @user1.id)}.should raise_error(
        ActiveModel::MassAssignmentSecurity::Error)
    end    
  end

  context "when user is not present" do
    before{ @booking.user_id = nil}
    it{ should_not be_valid}
  end

  context "when court_day is not present" do
    before{ @booking.court_day = nil}
    it{ should_not be_valid}
  end

  context "when session is not present" do
    before{ @booking.session = nil}
    it{ should_not be_valid}
  end

  context "when session is neither :morning nor :afternoon" do
    before{ @booking.session = 0}
    it{ should_not be_valid}
  end
end

