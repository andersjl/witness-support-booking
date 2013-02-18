require 'spec_helper'

describe DatabasesController do
  context "authorization," do
    it_requires_login :new, :create, :show
    it_requires_enabled :new, :create, :show
    it_requires_admin :new, :create, :show
  end
end
