require 'spec_helper'

describe UsersController do
  context "authorization," do
    it_is_open :new, :create
    it_is_private :edit, :update
    it_requires_enabled :index, :show
    it_requires_admin [ :enable, :put, :member], :destroy do
      create_test_user.id
    end
  end
end

