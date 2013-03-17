require 'spec_helper'

describe CourtDaysController do
  context "authorization," do
    it_requires_enabled :index
    it_requires_admin :update do
      [ create_test_court_day.date, :cannot_test_other_court_admin]
    end
  end
end

