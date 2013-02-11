require 'spec_helper'

describe "CourtDay model" do

  before{ @court_day = create_test_court_day :do_not_save => true}
  subject{ @court_day}

  it{ should respond_to( :date)}
  it{ should respond_to( :morning)}
  it{ should respond_to( :afternoon)}
  it{ should respond_to( :notes)}
  it{ should respond_to( :bookings)}
  it{ should respond_to( :morning_bookings)}
  it{ should respond_to( :afternoon_bookings)}
  it{ should be_valid}

  context "when date is missing" do
    before{ @court_day.date = nil}
    it{ should_not be_valid}
  end

  context "when date is taken" do
    before{ create_test_court_day :date => @court_day.date, :morning => 1,
                                  :afternoon => 2, :notes => "Babbel"}
    it{ should_not be_valid}
  end

  context "when morning is missing" do
    before{ @court_day.morning = nil}
    it{ should_not be_valid}
  end

  context "when morning is < 0" do
    before{ @court_day.morning = -1}
    it{ should_not be_valid}
  end

  context "when morning is > #{ PARALLEL_SESSIONS_MAX}" do
    before{ @court_day.morning = PARALLEL_SESSIONS_MAX + 1}
    it{ should_not be_valid}
  end

  context "when afternoon is missing" do
    before{ @court_day.afternoon = nil}
    it{ should_not be_valid}
  end

  context "when afternoon is < 0" do
    before{ @court_day.afternoon = -1}
    it{ should_not be_valid}
  end

  context "when afternoon is > #{ PARALLEL_SESSIONS_MAX}" do
    before{ @court_day.afternoon = PARALLEL_SESSIONS_MAX + 1}
    it{ should_not be_valid}
  end

  context "when nothing to do" do
    before do
      @court_day.morning = @court_day.afternoon = 0
      @court_day.notes = "\t  \n  "
    end
    it{ should_not be_valid}
  end

  context "earliest first" do
    before do
      @court_day.save!
      @later = create_test_court_day :date => Date.tomorrow
    end
    it{ CourtDay.find( :first).should == @court_day}
  end

  [ :morning, :afternoon].each do |session|
    context "when booking #{ session}" do
      before do
        @court_day.send "#{ session}=", 2
        @court_day.save!
        @user = create_test_user
        @user.book! @court_day, session
      end
      it{ @court_day.send( "#{ session}_bookings").count.should == 1}
      it "correct user and session" do
        @court_day.bookings.first.user.should == @user
        @court_day.bookings.first.session.should == session
      end
    end
  end
end

