require 'spec_helper'

describe UsersController do
  context "authorization," do
    it_is_open :new, :create
    it_is_protected :edit, :update
    it_requires_enabled :index, :show
    it_requires_admin [ :disable, :put, :member], [ :enable, :put, :member],
                      [ :promote, :put, :member], :destroy do |correct_admin|
      create_test_user email: "test@example.com", court: correct_admin.court
    end
  end
end

