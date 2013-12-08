require 'spec_helper' 

describe "CourtSession model" do

  before{ @session = create_test_court_session do_not_save: true}
  subject{ @session}

  it{ should respond_to :court}
  it{ should respond_to :date}
  it{ should respond_to :start}
  it{ should respond_to :need}
  it{ should respond_to :bookings}

  context "validation" do

    context "when court is missing" do
      before{ @session.court = nil}
      it{ should_not be_valid}
    end

    context "when date is missing" do
      before{ @session.date = nil}
      it{ should_not be_valid}
    end

    [ "Saturday", "Sunday"].each do |weekend_day|
      context "when on a #{ weekend_day}" do
        before do
          date = @session.date
          @session.update_attribute :date,
            date - (date.cwday + (weekend_day == "Saturday" ? 1 : 0)) + 7
          @session.valid?
        end
        it{ should_not be_valid}
        context "errors" do
          subject{ @session.errors}
          its( [ :date]){ should include( t( "court_day.error.weekend",
                        dow: t( "date.day_names")[ @session.date.cwday % 7]))}
        end
      end
    end

    context "when start is missing" do
      before{ @session.start = nil}
      it{ should_not be_valid}
    end

    context "when start is not numerical" do
      before{ @session.start = Object.new}
      it{ should_not be_valid}
    end

    context "when start is not an integer" do
      before{ @session.start = rand 0}
      it{ should_not be_valid}
    end

    context "when start is equal to -1" do
      before{ @session.start = -1}
      it{ should_not be_valid}
    end

    context "when start is equal to #{ 24 * 60 * 60}" do
      before{ @session.start = 24 * 60 * 60}
      it{ should_not be_valid}
    end

    context "when start is taken" do
      before do
        @other = create_test_court_session court: @session.court,
                   date: @session.date, start: @session.start
        @session.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @session.errors}
        its( [ :start]){
          should include( t( "court_session.error.start_taken"))}
      end
      context "on another date" do
        before{ @other.update_attribute :date, @session.date + 1}
        it{ should be_valid}
      end
      context "on another court" do
        before{ @other.update_attribute :court,
                                        Court.create!( name: "Yet another")}
        it{ should be_valid}
      end
    end

    context "when need is missing" do
      before{ @session.need = nil}
      it{ should_not be_valid}
    end

    context "when need is -1" do
      before{ @session.need = -1}
      it{ should_not be_valid}
    end

    context "when need is #{ PARALLEL_SESSIONS_MAX + 1}" do
      before{ @session.need = PARALLEL_SESSIONS_MAX + 1}
      it{ should_not be_valid}
    end

    context "when need is zero" do

      before do
        @session.save!
        @session.need = 0
      end

      context "unbooked" do
        before{ @session.valid?}
        it{ should_not be_valid}
        context "errors" do
          subject{ @session.errors}
          its( [ :need]){
            should include( t( "court_session.error.no_reason_to_exist",
                               session: @session.inspect))}
        end
      end

      context "booked" do
        before do
          @session.update_attribute :need, 1
          Booking.create! user: create_test_user, court_session: @session
          @session.update_attribute :need, 0
          @session.reload
        end
        it{ should be_valid}
      end
    end
  end

  context "earliest first" do
    before do
      create_test_court_session date: CourtDay.add_weekdays( @session.date, 3)
      @session.save!
      create_test_court_session date: CourtDay.add_weekdays( @session.date, 1)
    end
    specify{ CourtSession.find_by( court_id: @session.court
                                 ).should == @session}
  end
end

