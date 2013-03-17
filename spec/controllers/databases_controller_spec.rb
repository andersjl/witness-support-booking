require 'spec_helper'

describe DatabasesController do
  context "authorization," do
    it_requires_master :new, :create, :show
  end
end
