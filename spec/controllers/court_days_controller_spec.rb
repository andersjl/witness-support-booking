require 'spec_helper'

describe CourtDaysController, :type => :controller do
  context "authorization," do
    it_requires_enabled :index
  end
end

