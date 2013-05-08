require 'spec_helper'

describe CourtDayNotesController do
  context "authorization," do
    it_requires_admin :create, :update do |correct_admin|
      create_test_court_day_note court: correct_admin.court
    end
  end
end

