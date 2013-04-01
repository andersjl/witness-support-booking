require 'spec_helper'

describe "Booking model" do

  before do
    @court_day = create_test_court_day :morning => 1, :afternoon => 2
    @user = create_test_user
    @booking = @user.bookings.build :court_day_id => @court_day.id,
                                    :session => :afternoon
  end

  subject{ @booking}

  it{ should respond_to( :user)}
  it{ should respond_to( :court_day)}
  it{ should respond_to( :session)}
  it{ should be_valid}

  describe "accessible attributes" do
    it "should not allow access to user_id" do
      lambda{ Booking.new( :user_id => @user.id)}.should raise_error(
        ActiveModel::MassAssignmentSecurity::Error)
    end    
  end

  describe "validation" do

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

    context "when overbooking the session" do
      before do
        @court_day.update_attribute( :afternoon, 0)
        @booking.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @booking.errors}
        its( [ :base]){ should include(
              t( "booking.full", court_day: @booking.court_day.inspect,
                 session: t( "booking.afternoon.short")))}
      end
    end

    context "when user and court_day have different courts" do
      before do
        @court_day = create_test_court_day :court => create_test_court(
                                                       :name => "Other"),
                                           :morning => 1, :afternoon => 2
        @booking = @user.bookings.build :court_day_id => @court_day.id,
                                        :session => :morning
        @booking.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @booking.errors}
        its( [ :base]){ should include(
              t( "booking.court_mismatch",
                 court_day: @booking.court_day.inspect,
                 user: @booking.user.inspect))}
      end
    end
  end

  describe "cascading" do

    before{ @booking.save!}

    context "when user is destroyed" do
      before{ @user.destroy}
      specify{ expect{ @booking.reload
                     }.to raise_error ActiveRecord::RecordNotFound}
    end

    context "when court_day is destroyed" do
      before{ @court_day.destroy}
      specify{ expect{ @booking.reload
                     }.to raise_error ActiveRecord::RecordNotFound}
    end
  end
end

