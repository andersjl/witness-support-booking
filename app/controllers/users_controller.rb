class UsersController < ApplicationController
extend Authorization

  before_action :cookies_required, :only => :new

  authorize [ :index, :show], [ "normal", "admin", "master"]
  authorize [ :edit, :update],
            [ "disabled", "normal", "admin", "master"] do |params, user|
    user.id == params[ :id].to_i || user.master? ||
      (user.admin? && User.find( params[ :id]).court == user.court)
  end
  authorize [ :disable, :enable, :promote, :destroy],
            [ "admin", "master"] do |params, user|
    if user.id == params[ :id].to_i
      false
    else
      affected_user = User.find params[ :id]
      affected_user &&
        ( (user.master? && !affected_user.master?
          ) || (!affected_user.admin? && affected_user.court == user.court))
    end
  end

  def new
    @user = User.new
    Court.create!( name: t( "court.default")) if Court.count == 0
    @courts = Court.all
  end

  def create
    user = User.new
    user.court_id              = params[ :user][ :court]
    user.email                 = params[ :user][ :email]
    user.name                  = params[ :user][ :name]
    user.password              = params[ :user][ :password]
    user.password_confirmation = params[ :user][ :password_confirmation]
    if user.save
      log_in user
      flash[ :success] = t( "user.created", name: user.name)
      redirect_to root_path
    else
      @user = user
      @courts = Court.all
      render "new"
    end
  end

  def index
    if current_user.master?
      @users =
        Court.all.inject( [ ]){ |a, c| a += User.order_by_role_and_name( c)}
    else
      @users = User.order_by_role_and_name( current_user.court)
      @court = current_user.court
    end
  end

  def show; show_or_edit end
  def edit; show_or_edit end
  def show_or_edit
    @user = User.find params[ :id]
    redirect_to users_path unless @user
    if @user.master?
      @database = Database.new
      @count_date = session[ :count_date] || @database.oldest_date
    end
  end
  private :show_or_edit

  # reads only selected parts of <tt>params</tt> depending of who is logged
  # in, NEVER changes <tt>court</tt>
  def update
    @user = User.find params[ :id]
    if @user
      if current_user? @user
        @user.email               = params[ :user][ :email]
        @user.name                = params[ :user][ :name]
      end
      @user.password              = params[ :user][ :password]
      @user.password_confirmation = params[ :user][ :password_confirmation]
      if @user.save
        if current_user? @user
          log_in @user  # because remember_token has been reset
          flash.now[ :success] = t( "user.changed.message")
          back_to_court_days
        else
          flash[ :success] = t( "user.changed.password", name: @user.name)
          redirect_to users_path
        end
      else
        render 'edit'
      end
    else
      redirect_to users_path
    end
  end

  def disable; update_role_do( "disabled") end
  def enable;  update_role_do( "normal")   end
  def promote; update_role_do( "admin")    end
  def update_role_do( role)
    @user = User.find params[ :id]
    if @user
      old_role = @user.role
      if User.valid_role?( role) && @user.update_attribute( :role, role)
        flash[ :success] = t( "user.role.changed",
                              name: @user.name,
                              from: t( "user.role.#{ old_role}"),
                              to: t( "user.role.#{ role}"))
      else
        flash[ :error] = t( "user.role.change_fail",
                            name: @user.name,
                            from: t( "user.role.#{ old_role}"),
                            to: t( "user.role.#{ role}"))
      end
    end
    redirect_to users_path
  end
  private :update_role_do

  def destroy
    destroyed = User.find params[ :id]
    if destroyed
      destroyed_inspect = destroyed.inspect
      destroyed.destroy
      flash[ :success] = t( "user.destroyed", user: destroyed_inspect)
    end
    redirect_to users_path
  end
end

