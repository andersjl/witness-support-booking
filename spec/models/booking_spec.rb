require 'spec_helper'

describe "Booking model" do

  before do
    @user = create_test_user
    @session = create_test_court_session court: @user.court, need: 2
    @booking = Booking.create!( user: @user, court_session: @session)
  end

  subject{ @booking}

  it{ should be_valid}
  it{ should respond_to :user}
  it{ should respond_to :court_session}

  describe "validation" do

    context "when user is not present" do
      before{ @booking.user = nil}
      it{ should_not be_valid}
    end

    context "when court_session is not present" do
      before{ @booking.court_session = nil}
      it{ should_not be_valid}
    end

    context "when overbooking the session" do
      before do
        @session.update_attribute( :need, 0)
        @booking.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @booking.errors}
        its( [ :base]){ should include( t( "booking.error.full", court_session:
                                           @booking.court_session.inspect))}
      end
    end

    context "when user and court_session have different courts" do
      before do
        @session = create_test_court_session(
                     court: create_test_court( name: "Other"), need: 2)
        @booking = Booking.new user: @user, court_session: @session
        @booking.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @booking.errors}
        its( [ :base]){ should include(
              t( "booking.error.court_mismatch",
                 court_session: @booking.court_session.inspect,
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

    context "when court_session is destroyed" do
      before{ @session.destroy}
      specify{ expect{ @booking.reload
                     }.to raise_error ActiveRecord::RecordNotFound}
    end
  end
end

