require 'spec_helper'

describe BookingsController do
  context "authorization," do
    it_requires_admin :destroy do
      create_test_user.book!( create_test_court_day( :morning => 1), :morning
                            ).id
    end
  end
end

