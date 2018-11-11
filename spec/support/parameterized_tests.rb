
# Authorization tests ========================================================
# Each action is a method symbol, i.e. :index.  The request used is inferred
# from the method.
# An optional block may return a model object that is used as parameters to
# the tested action.  The block may be given a "correct" user as parameter.

def it_is_open( *actions, &block)
  context "requires no login" do
    before{ get_tested_member block}
    context "allowed for unknown user:" do
      verify_reachable actions
    end
    USER_ROLES.each do |role|
      context "allowed for #{ role} user:" do
        before{ @user = create_test_user role: role}
        verify_reachable actions
      end
    end
  end
end

def it_requires_login( *actions, &block)
  context "requires logged in user" do
    before{ get_tested_member block}
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    USER_ROLES.each do |role|
      context "allowed for #{ role} user:" do
        before{ @user = create_test_user role: role}
        verify_reachable actions
      end
    end
  end
end

def it_requires_enabled( *actions, &block)
  context "requires enabled user" do
    before{ get_tested_member block}
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    context "protected from disabled user:" do
      before{ @user = create_test_user( role: "disabled")}
      verify_reachable actions, false
    end
    (USER_ROLES - [ "disabled"]).each do |role|
      context "allowed for #{ role} user:" do
        before{ @user = create_test_user( role: role)}
        verify_reachable actions
      end
    end
  end
end

# a block is necessary unles the tested resource is :user
def it_is_private( *actions, &block)
  it_is_private_do false, actions, block
end
def it_is_protected( *actions, &block)
  it_is_private_do true, actions, block
end
def it_is_private_do( allow_admin, actions, block)
  context( "requires correct user" + (allow_admin ? " or admin" : "")) do
    before do
      @correct_user = create_test_user
      get_tested_member block
    end
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    (allow_admin ? [ "disabled", "normal"] : USER_ROLES).each do |role|
      context "protected from other #{ role} user:" do
        before{ @user = create_test_user name:  "Wrong User",
                                         email: "wrong@example.com",
                                         role:  role}
        verify_reachable actions, false
      end
    end
    context "allowed for correct user:" do
      before{ @user = @correct_user}
      verify_reachable actions
    end
    if allow_admin
      context "protected from wrong court admin:" do
        before{ @user = create_test_user(
                          name:  "Wrong Admin",
                          email: "admin.other.court@example.com",
                          court: create_test_court( name: "Wrong court"),
                          role:  "admin")}
        verify_reachable actions, false
      end
      context "allowed for court admin:" do
        before{ @user = create_test_user(
                          name:  "Court Admin",
                          email: "admin.this.court@example.com",
                          court: @correct_user.court,
                          role:  "admin")}
        verify_reachable actions
      end
      context "allowed for master:" do
        before{ @user = create_test_user(
                          name:  "Master",
                          email: "master.other.court@example.com",
                          court: create_test_court( name: "Wrong court"),
                          role:  "master")}
        verify_reachable actions
      end
    end
  end
end

# a block is necessary
def it_requires_admin( correct, *actions, &block)
  context "requires admin" do
    before do
      @correct_user = create_test_user email: "admin@example.com",
                                       role:  "admin"
      get_tested_member block
    end
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    [ "disabled", "normal"].each do |role|
      context "protected from #{ role} user:" do
        before{ @user = create_test_user court: @correct_user.court,
                                         email: "#{ role}@example.com",
                                         role: role}
        verify_reachable actions, false
      end
    end
    if correct
      context "protected from wrong court admin:" do
        before{ @user = create_test_user(
                          court: create_test_court( name: "Wrong court"),
                          email: "admin@example.com", role: "admin")}
        verify_reachable actions, false
      end
    end
    context "allowed for court admin:" do
      before{ @user = @correct_user}
      verify_reachable actions
    end
    context "allowed for master:" do
      before{ @user = create_test_user(
                        court: create_test_court( name: "Wrong court"),
                        email: "master@example.com", role: "master")}
      verify_reachable actions
    end
  end
end

def it_requires_master( *actions, &block)
  context "requires master" do
    before do
      @correct_user = create_test_user email: "admin@example.com",
                                       role: "master"
      get_tested_member block
    end
    context "protected from unknown user:" do
      verify_reachable actions, false
    end
    (USER_ROLES - [ "master"]).each do |role|
      context "protected from #{ role} user:" do
        before{ @user = create_test_user email: "#{ role}@example.com",
                                         role: role}
        verify_reachable actions, false
      end
    end
    context "allowed for master:" do
      before{ @user = @correct_user}
      verify_reachable actions
    end
  end
end

ACTION_DEFS_DEFAULT =
  { new:      [ :get,    :member],
    create:   [ :post,   :collection],
    index:    [ :get,    :collection],
    show:     [ :get,    :member],
    edit:     [ :get,    :member],
    update:   [ :put,    :member],
    destroy:  [ :delete, :member]}

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
      if reachable
      # expect( controller).to receive( action)  -- does not redirect
        controller.instance_eval %Q$
          def #{ action}( *args)
            raise "reached"
          end$
        lambda{ verify_reachable_trigger action, method, target
              }.should raise_error( "reached")
      else
        expect( controller).not_to receive( action)
        verify_reachable_trigger action, method, target
      end
    end
  end
end

def verify_reachable_trigger( action, method, target)
  args = { }
  if @tested_member
    args[ :id] = @tested_member.id if target == :member
    attrs = @tested_member.attributes
    attrs.delete "id"
    attrs.delete "password_digest"
    attrs.delete "remember_token"
    attrs.delete "created_at"
    attrs.delete "updated_at"
    args[ @tested_member.class.name.underscore] = attrs
  elsif target == :member
    args[ :id] = :any_id
  end
  send method, action,
    { params:  args,
      session: { remember_token: @user && @user.remember_token}
    }
end

def get_tested_member( block)
  return unless @correct_user
  if block
    @tested_member = block.call @correct_user
  else
    @tested_member = @correct_user
  end
end

