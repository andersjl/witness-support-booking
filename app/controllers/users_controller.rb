class UsersController < ApplicationController
extend Authorization

  authorize [ :index, :show], [ "normal", "admin"]
  authorize [ :edit, :update], [ "disabled", "normal", "admin"] do |id, user|
    user.id == id.to_i || user.admin?
  end
  authorize [ :enable, :destroy], "admin" do |id, user|
    affected_user = User.find( id)
    affected_user != user && !affected_user.admin?
  end

  def new
    @user = User.new
  end
 
  def create
    @user = User.new( params[ :user])
    if @user.save
      log_in @user
      flash[ :success] = "Välkommen #{ @user.name}!"
      redirect_to root_path
    else
      render "new"
    end
  end

  def index
    @users = User.order_by_role_and_name
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
    when VALUE_BOOK_MORNING     then update_book_do( :morning)
    when VALUE_BOOK_AFTERNOON   then update_book_do( :afternoon)
    when VALUE_UNBOOK_MORNING   then update_unbook_do( :morning)
    when VALUE_UNBOOK_AFTERNOON then update_unbook_do( :afternoon)
    else
      if @user.update_attributes( params[ :user])
        if @user == current_user
          log_in @user  # because remember_token has been reset
          flash.now[ :success] = "Uppgifterna sparade"
          back_to_court_days
        else
          flash[ :success] = "Lösenordet ändrat"
          redirect_to users_path
        end
      else
        render 'edit'
      end
    end
  end

  def enable
    update_role_do( "normal"){ [ "aktiverad", "aktiveras"]}
  end

  def destroy
    destroyed = User.find params[ :id]
    destroyed_inspect = destroyed.inspect
    destroyed.destroy
    flash[ :success] = "Användare #{ destroyed_inspect}) borttagen"
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
    if User.valid_role?( role) && @user.update_attribute( :role, role)
      flash[ :success] = "Användare #{ @user.inspect} #{ yield[ 0]}"
    else
      flash[ :error] = "Användare #{ @user.inspect} kunde inte #{ yield[ 1]}"
    end
    redirect_to users_path
  end
  private :update_role_do
end

