# Authorization tests ========================================================
# Each action is a method symbol, i.e. :index.  The request used is inferred
# from the method.

def it_requires_login( *actions)
  context "requires login:" do
    verify_actions_unreachable actions
  end
end

def it_requires_enabled( *actions)
  context "requires enabled user:" do
    before do
      @user = create_test_user
      @user.update_attribute :role, "disabled"
      fake_log_in @user
    end
    verify_actions_unreachable actions
  end
end

def it_is_private( *actions)
  context "private:" do
    before do
      @user = create_test_user
      @wrong_user = create_test_user( :name => "Wrong User",
                                      :email => "wrong@example.com")
      fake_log_in @user
      @tested_member_id = @wrong_user.id
    end
    verify_actions_unreachable actions
  end
end

def it_requires_admin( *actions)
  context "requires admin:" do
    before do
      @user = create_test_user
      fake_log_in @user
    end
    verify_actions_unreachable actions
  end
end

ACTION_DEFS_DEFAULT =
  { :new      => [ :get,    :member],
    :create   => [ :post,   :collection],
    :index    => [ :get,    :collection],
    :show     => [ :get,    :member],
    :edit     => [ :get,    :member],
    :update   => [ :put,    :member],
    :destroy  => [ :delete, :member]}

def verify_actions_unreachable( actions)
  member_id = @tested_member_id ? @tested_member_id : 1000000000
  actions.each do |action|
    if action.is_a? Array
      action, method, target = action
    elsif ACTION_DEFS_DEFAULT[ action]
      method, target = ACTION_DEFS_DEFAULT[ action]
    else
      raise "#{ action.inspect} should be one of #{
        ACTION_DEFS_DEFAULT.keys.join ', '}"
    end
    it action do
      controller.should_not_receive action
      if target == :collection
        send method, action
      else
        send method, action, :id => member_id
      end
    end
  end
end

=begin
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

def it_requires_enabled( *actions)
  context "requires enabled user:" do
    before do
      @user = create_test_user
      @user.update_attribute :role, "disabled"
      fake_log_in @user
    end
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
      fake_log_in @user
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

def it_requires_admin( *actions)

  context "requires admin:" do

    before do
      @user = create_test_user
      fake_log_in @user
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
=end

