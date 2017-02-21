require 'spec_helper'

describe BookingsController, :type => :controller do
  context "authorization," do
    it_is_private :create do |correct_user|
      session = create_test_court_session( court: correct_user.court)
      Booking.new user:          correct_user,
                  court_session: session,
                  booked_at:     session.date - rand( 10)
    end
    it_is_protected :destroy do |correct_user|
      session = create_test_court_session( court: correct_user.court)
      Booking.create! user:          correct_user,
                      court_session: session,
                      booked_at:     session.date - rand( 10)
    end
  end
end

