require 'spec_helper'

describe UsersController do
  context "authorization," do
    it_requires_login :index, :show, :edit, :update,
                      [ :enable, :put, :member], :destroy
    it_requires_enabled :index, :show, [ :enable, :put, :member], :destroy
    it_is_private :edit, :update
    it_requires_admin [ :enable, :put, :member], :destroy
  end
end

