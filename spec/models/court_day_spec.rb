require 'spec_helper'

describe "CourtDay model" do

  before{ @court_day = create_test_court_day :do_not_save => true}
  subject{ @court_day}

  it{ should respond_to( :date)}
  it{ should respond_to( :morning)}
  it{ should respond_to( :afternoon)}
  it{ should respond_to( :notes)}
  it{ should respond_to( :court)}
  it{ should respond_to( :bookings)}
  it{ should respond_to( :morning_bookings)}
  it{ should respond_to( :afternoon_bookings)}
  it{ should be_valid}

  context "validation" do

    context "when court is missing" do
      before{ @court_day.court = nil}
      it{ should_not be_valid}
    end

    context "when date is missing" do
      before{ @court_day.date = nil}
      it{ should_not be_valid}
    end

    context "when date is taken" do
      before do
        @other_court_day = create_test_court_day :date => @court_day.date,
                                                 :morning => 1
        @court_day.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @court_day.errors}
        its( [ :date]){ should include( t( "court_day.date.taken"))}
      end
      context "on another court" do
        before{ @other_court_day.
                  update_attribute :court, Court.create!( :name => "Other")}
        it{ should be_valid}
      end
    end

    [ :morning, :afternoon].each do |session|
      context "when #{ session} is missing" do
        before{ @court_day.send( "#{ session}=", nil)}
        it{ should_not be_valid}
      end

      context "when #{ session} is < 0" do
        before{ @court_day.send( "#{ session}=", -1)}
        it{ should_not be_valid}
      end

      context "when #{ session} is > #{ PARALLEL_SESSIONS_MAX}" do
        before{ @court_day.send( "#{ session}=", PARALLEL_SESSIONS_MAX + 1)}
        it{ should_not be_valid}
      end
    end

    [ "Saturday", "Sunday"].each do |weekend_day|
      context "when on a #{ weekend_day}" do
        before do
          @date = @court_day.date - (@court_day.date.cwday +
                                      (weekend_day == "Saturday" ? 1 : 0)) + 7
          @court_day.update_attribute( :date, @date)
          @court_day.valid?
        end
        it{ should_not be_valid}
        context "errors" do
          subject{ @court_day.errors}
          its( [ :date]){ should include( t( "court_day.date.weekend",
                   date: @date, dow: t( "date.day_names")[ @date.cwday % 7]))}
        end
      end
    end

    context "when nothing to do" do
      before do
        @court_day.morning = @court_day.afternoon = 0
        @court_day.notes = "\t  \n  "
        @court_day.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @court_day.errors}
        its( [ :base]){ should include( t( "court_day.empty",
                     date: @court_day.date, court: @court_day.court.name))}
      end
    end
  end

  context "earliest first" do
    before do
      create_test_court_day :date => Date.tomorrow + 2
      @court_day.save!
      create_test_court_day :date => Date.tomorrow
    end
    it{ CourtDay.find( :first,
                       :conditions => ["court_id = ?", court_this.id]
                     ).should == @court_day}
  end

  [ :morning, :afternoon].each do |session|
    context "when booking #{ session}" do
      before do
        @court_day.send "#{ session}=", 2
        @court_day.save!
        @user = create_test_user
        @user.book! @court_day, session
      end
      specify{ @court_day.send( "#{ session}_bookings").count.should == 1}
      specify "correct user and session" do
        @court_day.bookings.first.user.should == @user
        @court_day.bookings.first.session.should == session
      end
      specify "destroyed along with self" do
        expect{ @court_day.destroy}.to change( Booking, :count).by( -1)
      end
    end
  end

  context "when court is destroyed" do
    before do
      @court_day.save!
      @court_day.court.destroy
    end
    specify{ expect{ @court_day.reload
                   }.to raise_error ActiveRecord::RecordNotFound}
  end
end

