require 'spec_helper'

describe CourtSessionsController, :type => :controller do
  context "authorization," do
    it_requires_admin :correct, :create, :update do |correct_admin|
      create_test_court_session court: correct_admin.court
    end
  end
end

