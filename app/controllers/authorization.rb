# extend your controller class with this module
module Authorization

  def authorize( action, role, &condition)
    actions = [ action].flatten
    roles = [ role].flatten
    filter_sym = "authorize_#{ roles.join '_'}".intern
    before_filter filter_sym, :only => actions
    define_method filter_sym do
      role = logged_in? ? current_user.role : "unknown"
      redirect_to( root_path) if !roles.include?( role) ||
                                   condition &&
                                     !condition.call( params, current_user)
    end
  end
end

