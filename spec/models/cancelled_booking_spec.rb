require 'spec_helper'

describe "CancelledBooking model" do

  before do
    @user = create_test_user
    @session = create_test_court_session court: @user.court, need: 1
    @cancelled = CancelledBooking.create! user: @user,
                   court_session: @session, cancelled_at: Time.current
  end

  subject{ @cancelled}

  it{ should respond_to :user}
  it{ should respond_to :court_session}
  it{ should respond_to :cancelled_at}

  context ".purge_old" do

    def expect_purge( total, purged)
      case total
      when 0 then @cancelled.delete
      when 1 then # do nothing
      else
        [ create_test_court_session( court: @user.court, count: total - 1)
        ].flatten.each{ |s| CancelledBooking.create user: @user,
                              court_session: s, cancelled_at: Time.current}
      end
      CourtSession.all.each{ |s| s.update_attribute :date,
                                     s.date - BOOKING_DAYS_AHEAD_MAX - 14}
      CancelledBooking.purge_old
      CancelledBooking.count.should == total - purged
    end

    specify( "purge 0 of 0"){ expect_purge 0, 0}
    specify( "purge 1 of 1"){ expect_purge 1, 1}
    specify( "purge 1 of 10"){ expect_purge 10, 1}
    specify( "purge 2 of 11"){ expect_purge 11, 2}
  end

  describe "cascading" do

    context "when user is destroyed" do
      before{ @user.destroy}
      specify{ expect{ @cancelled.reload
                     }.to raise_error ActiveRecord::RecordNotFound}
    end

    context "when court_session is destroyed" do
      before{ @session.destroy}
      specify{ expect{ @cancelled.reload
                     }.to raise_error ActiveRecord::RecordNotFound}
    end
  end
end

