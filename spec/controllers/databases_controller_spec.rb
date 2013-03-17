require 'spec_helper'

describe DatabasesController do
  context "authorization," do
    it_requires_admin( :new, :create, :show){ :dummy_id}
  end
end
