require 'spec_helper'

describe BookingsController, :type => :controller do
  context "authorization," do
    it_is_private :create do |correct_user|
      Booking.new user: correct_user,
        court_session: create_test_court_session( court: correct_user.court)
    end
    it_is_protected :destroy do |correct_user|
      Booking.create! user: correct_user,
        court_session: create_test_court_session( court: correct_user.court)
    end
  end
end

