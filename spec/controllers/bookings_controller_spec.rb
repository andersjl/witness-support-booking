require 'spec_helper'

describe BookingsController do
  context "authorization," do
    it_requires_login :destroy
    it_requires_enabled :destroy
    it_requires_admin :destroy
  end
end

