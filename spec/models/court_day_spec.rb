require 'spec_helper'

describe CourtDay do

  before{ @court_day = create_test_court_day :do_not_save => true}
  subject{ @court_day}

  it{ should respond_to( :date)}
  it{ should respond_to( :morning)}
  it{ should respond_to( :afternoon)}
  it{ should respond_to( :notes)}
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
      @later = create_test_court_day :date => Date.tomorrow
      @court_day.save!
    end
    it{ CourtDay.find( :first).should == @court_day}
  end
end

