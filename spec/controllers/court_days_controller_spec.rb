require 'spec_helper'

describe CourtDaysController do
  context "authorization," do
    it_requires_login :index, :edit  #, :update
    it_is_not_accessible_for_non_admin_users :edit  # :update
  end
end

