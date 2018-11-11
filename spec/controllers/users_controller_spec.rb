require 'spec_helper'

describe UsersController, :type => :controller do
  context "authorization," do
    it_is_open :create  # new not tested, clashes with cookie detection
    it_is_protected :edit, :show, :update
    it_requires_admin false, :index
    it_requires_admin(
        :correct,
        :destroy,
        [ :disable, :put, :member],
        [ :enable,  :put, :member],
        [ :promote, :put, :member],
    ) do |correct_admin|
      create_test_user email: "test@example.com", court: correct_admin.court
    end
  end
end

