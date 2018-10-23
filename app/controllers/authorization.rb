=begin rdoc
Usage:
  class MyController < ApplicationController
  extend Authorization
    aurhorise [ :action_1, :action_2], [ role_1, role_2] do |params, user|
      an_optional_block_returning_true_if_the_user_is_authorized
    end
    ...
  end
Without block, the user roles role_1 and role_2 are authorized to action_1 and
action_2.  With block, the block must also return true.
=end
module Authorization

  def authorize( action, role, &condition)
    actions = [ action].flatten
    roles = [ role].flatten
    filter_sym = "authorize_#{ (actions + roles).join '_'}".intern
    before_action filter_sym, :only => actions
    define_method filter_sym do
      role = logged_in? ? current_user.role : "unknown"
      if !roles.include?( role) || condition &&
                                     !condition.call( params, current_user)
        flash.keep
        redirect_to( root_path)
      end
    end
  end
end

