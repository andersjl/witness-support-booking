require 'spec_helper'

describe DatabasesController, :type => :controller do
  context "authorization," do
    it_requires_master :new, :create, :show, :update
  end
end
