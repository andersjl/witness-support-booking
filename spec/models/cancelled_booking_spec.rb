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

