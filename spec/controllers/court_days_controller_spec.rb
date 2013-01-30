require 'spec_helper'

describe CourtDaysController do
  context "authorization," do
    it_requires_login :index  #, :update
  # it_is_not_accessible_for_non_admin_users :update
  end
end

