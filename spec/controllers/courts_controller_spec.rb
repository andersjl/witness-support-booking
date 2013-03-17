require 'spec_helper'

describe CourtsController do
  context "authorization," do
    it_requires_master :create, :index, :edit, :update, :destroy
  end
end

