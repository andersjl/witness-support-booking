class UsersController < ApplicationController
extend Authorization

  authorize [ :index, :show], [ "normal", "admin", "master"]
  authorize [ :edit, :update],
            [ "disabled", "normal", "admin", "master"] do |id, user|
    user.id == id.to_i || user.master? ||
      (user.admin? && User.find( id).court == user.court)
  end
  authorize [ :disable, :enable, :promote, :destroy],
            [ "admin", "master"] do |id, user|
    if user.id == id.to_i
      false
    else
      affected_user = User.find id
      (user.master? && !affected_user.master?) ||
        (!affected_user.admin? && affected_user.court == user.court)
    end
  end

  def new
    @user = User.new
    Court.create!( name: t( "court.default")) if Court.count == 0
    @courts = Court.all
  end

  def create
    court_id = params[ :user].delete( :court_id)
    @user = User.new( params[ :user])
    @user.court_id = court_id
    if @user.save
      log_in @user
      flash[ :success] = t( "user.created", name: @user.name)
      redirect_to root_path
    else
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

  def show
    @user = User.find params[ :id]
  end

  def edit
    @user = User.find params[ :id]
  end

  def update
    @user = User.find params[ :id]
    case params[ :commit]
    when t( "booking.morning.book")     then update_book_do( :morning)
    when t( "booking.afternoon.book")   then update_book_do( :afternoon)
    when t( "booking.morning.unbook")   then update_unbook_do( :morning)
    when t( "booking.afternoon.unbook") then update_unbook_do( :afternoon)
    else
      if @user.update_attributes( params[ :user])
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
    end
  end

  def disable
    update_role_do( "disabled")
  end
  def enable
    update_role_do( "normal")
  end
  def promote
    update_role_do( "admin")
  end

  def destroy
    destroyed = User.find params[ :id]
    destroyed_inspect = destroyed.inspect
    destroyed.destroy
    flash[ :success] = t( "user.destroyed", user: destroyed_inspect)
    redirect_to users_path
  end

  def update_book_do( session)
    @user.bookings.create! :court_day_id => params[ :court_day],
                           :session => session
  rescue ActiveRecord::RecordInvalid => e
    flash[ :error] = e.message
  ensure
    back_to_court_days
  end
  private :update_book_do

  def update_unbook_do( session)
    @user.booked?( CourtDay.find( params[ :court_day]), session).destroy
    back_to_court_days
  end
  private :update_unbook_do

  def update_role_do( role)
    @user = User.find params[ :id]
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
    redirect_to users_path
  end
  private :update_role_do
end

