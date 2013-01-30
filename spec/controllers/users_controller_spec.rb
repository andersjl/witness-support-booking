require 'spec_helper'

describe UsersController do
  context "authorization," do
    it_requires_login :index, :edit, :update, :destroy
    it_is_private :edit, :update
    it_is_not_accessible_for_non_admin_users :destroy
  end
end

