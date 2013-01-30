
# each action is either a method symbol, i.e. :index.  The request used is
# inferred from the method.

def it_requires_login( *actions)
  context "requires login:" do
    actions.each do |action|
      it action do
        controller.should_not_receive action
        case action
        when :index, :new : get    action
        when :show, :edit : get    action, :id => 1  # any id is ok
        when :create      : post   action
        when :update      : put    action, :id => 1  # any id is ok
        when :destroy     : delete action, :id => 1  # any id is ok
        else raise "#{ action.inspect} should be :new, :create, index" +
                     ", :show, :edit, :update, or :destroy"
        end
      end
    end
  end
end

def it_is_private( *actions)

  context "private:" do

    before do
      @user = create_test_user
      @wrong_user = create_test_user( :name => "Wrong User",
                                      :email => "wrong@example.com")
      log_in @user
    end

    actions.each do |action|
      it action do
        controller.should_not_receive action
        case action
        when :show, :edit : get    action, :id => @wrong_user.id
        when :update      : put    action, :id => @wrong_user.id
        when :destroy     : delete action, :id => @wrong_user.id
        else raise action.inspect +
                     " should be :show, :edit, :update, or :destroy"
        end
      end
    end
  end
end

def it_is_not_accessible_for_non_admin_users( *actions)

  context "not accessible for non admin users:" do

    before do
      @user = create_test_user
      log_in @user
    end

    actions.each do |action|
      it action do
        controller.should_not_receive action
        case action
        when :index, :new : get    action
        when :show, :edit : get    action, :id => @user.id + 1  # any id is ok
        when :create      : post   action
        when :update      : put    action, :id => @user.id + 1  # any id is ok
        when :destroy     : delete action, :id => @user.id + 1  # any id is ok
        else raise "#{ action.inspect} should be :new, :create, index" +
                     ", :show, :edit, :update, or :destroy"
        end
      end
    end
  end
end

