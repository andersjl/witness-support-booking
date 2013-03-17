# Authorization tests ========================================================
# Each action is a method symbol, i.e. :index.  The request used is inferred
# from the method.
 
def it_is_open( *actions)
  context "requires no login" do
    context "allowed for unknown user:" do
      verify_reachable actions
    end
    USER_ROLES.each do |role|
      context "allowed for #{ role} user:" do
        before{ @user = create_test_user :role => role}
        verify_reachable actions
      end
    end
  end
end

def it_requires_login( *actions)
  context "requires logged in user" do
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    USER_ROLES.each do |role|
      context "allowed for #{ role} user:" do
        before{ @user = create_test_user :role => role}
        verify_reachable actions
      end
    end
  end
end

def it_requires_enabled( *actions)
  context "requires enabled user" do
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    context "protected from disabled user:" do
      before{ @user = create_test_user( :role => "disabled")}
      verify_reachable actions, false
    end
    (USER_ROLES - [ "disabled"]).each do |role|
      context "allowed for #{ role} user:" do
        before{ @user = create_test_user( :role => role)}
        verify_reachable actions
      end
    end
  end
end

def it_is_private( *actions)
  context "requires correct user" do
    before{ @tested_member_id = create_test_user.id}
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    [ "disabled", "normal"].each do |role|
      context "protected from other #{ role} user:" do
        before{ @user = create_test_user :name  => "Wrong User",
                                         :email => "wrong@example.com",
                                         :role  => role}
        verify_reachable actions, false
      end
    end
    context "protected from wrong court admin:" do
      before{ @user = create_test_user(
                        :name  => "Wrong Admin",
                        :email => "admin.other.court@example.com",
                        :court => court_other,
                        :role  => "admin")}
      verify_reachable actions, false
    end
    context "allowed for court admin:" do
      before{ @user = create_test_user(
                        :name  => "Court Admin",
                        :email => "admin.this.court@example.com",
                        :court => User.find( @tested_member_id).court,
                        :role  => "admin")}
      verify_reachable actions
    end
  end
end

# a block may supply a member ID for testing reachability of member actions
def it_requires_admin( *actions)
  context "requires admin" do
    before do
      member_info = yield
      if member_info.is_a?( Array)
        @tested_member_id, @tested_member_id_info = member_info
      else
        @tested_member_id = member_info
      end
    end
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    [ "disabled", "normal"].each do |role|
      context "protected from #{ role} user:" do
        before{ @user = create_test_user :email => "#{ role}@example.com",
                                         :role => role}
        verify_reachable actions, false
      end
    end
    context "protected from wrong court admin:" do
      before do
        if @tested_member_id_info == :cannot_test_other_court_admin
          @user = :not_testable
        else
          @user = create_test_user(
                          :court => create_test_court( :name => "Other"),
                          :email => "admin@example.com", :role => "admin")
        end
      end
      verify_reachable actions, false
    end
    context "allowed for court admin:" do
      before{ @user = create_test_user :email => "admin@example.com",
                                       :role => "admin"}
      verify_reachable actions
    end
  end
end

def it_requires_master( *actions)
  context "requires master" do
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    (USER_ROLES - [ "master"].each do |role|
      context "protected from #{ role} user:" do
        before{ @user = create_test_user :email => "#{ role}@example.com",
                                         :role => role}
        verify_reachable actions, false
      end
    end
    context "allowed for master:" do
      before{ @user = create_test_user :email => "admin@example.com",
                                       :role => "master"}
      verify_reachable actions
    end
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

def verify_reachable( actions, reachable = true)
  actions.each do |action|
    if action.is_a? Array
      action, method, target = action
    elsif ACTION_DEFS_DEFAULT[ action]
      method, target = ACTION_DEFS_DEFAULT[ action]
    else
      raise "#{ action.inspect} should be one of #{
        ACTION_DEFS_DEFAULT.keys.join ', '}"
    end
    specify action do
      unless @user == :not_testable
        if reachable
        # controller.should_receive action  -- does not redirect
          controller.instance_eval %Q$
            def #{ action}( *args)
              raise "reached"
            end$
          lambda{ verify_reachable_trigger action, method, target
                }.should raise_error( "reached")
        else
          controller.should_not_receive action
          verify_reachable_trigger action, method, target
        end
      end
    end
  end
end
 
def verify_reachable_trigger( action, method, target)
  if target == :collection
    send method, action, { },
         { :remember_token => @user && @user.remember_token}
  else
    send method, action, { :id => @tested_member_id || :no_id},
         { :remember_token => @user && @user.remember_token}
  end
end

