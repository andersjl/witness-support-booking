require 'spec_helper'

describe CourtDaysController do
  context "authorization," do
    it_requires_enabled :index
  end
end

