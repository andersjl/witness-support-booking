require 'spec_helper'

describe CourtSessionsController do
  context "authorization," do
    it_requires_admin :create, :update do |correct_admin|
      create_test_court_session court: correct_admin.court
    end
  end
end

