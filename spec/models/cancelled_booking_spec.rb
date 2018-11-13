require 'spec_helper'

describe "CancelledBooking model" do

  before do
    @user = create_test_user
    @session = create_test_court_session court: @user.court, need: 1
    @cancelled = CancelledBooking.create! user: @user,
                   court_session: @session, cancelled_at: Time.current
  end

  subject{ @cancelled}

  it{ should be_valid}
  it{ should respond_to :user}
  it{ should respond_to :court_session}
  it{ should respond_to :cancelled_at}

  describe "validation" do

    context "when user is not present" do
      before{ @cancelled.user = nil}
      it{ should_not be_valid}
    end

    context "when court_session is not present" do
      before{ @cancelled.court_session = nil}
      it{ should_not be_valid}
    end

    context "when user and court_session have different courts" do
      before do
        @session = create_test_court_session(
                     court: create_test_court( name: "Other"), need: 2)
        @cancelled = Booking.new user: @user, court_session: @session,
                               booked_at: @session.date - rand( 10)
        @cancelled.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @cancelled.errors}
        its( [ :base]){ should include(
              t( "booking.error.court_mismatch",
                 court_session: @cancelled.court_session.inspect,
                 user: @cancelled.user.inspect))}
      end
    end
  end

  describe "cascading" do

    context "when user is invalidated" do
      before{ @user.invalidate}
      specify{ expect{ @cancelled.reload}.not_to raise_error}
    end

    context "when court_session is destroyed" do
      before{ @session.destroy}
      specify{ expect{ @cancelled.reload
                     }.to raise_error ActiveRecord::RecordNotFound}
    end
  end
end

