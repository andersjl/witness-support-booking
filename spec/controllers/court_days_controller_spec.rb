require 'spec_helper'

describe CourtDaysController do
  context "authorization," do
    it_requires_login :index, :update
    it_requires_enabled :index, :update
    it_requires_admin :update
  end
end

