class UsersController < ApplicationController

  before_filter :logged_in_user,
                :only => [ :index, :show, :edit, :update, :enable, :destroy]
  before_filter :enabled_user, :only => [ :index, :show, :enable, :destroy]
  before_filter :correct_user, :only => [ :edit, :update]
  before_filter :admin_user, :only => [ :enable, :destroy]

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
      render 'new'
    end
  end

  def index
    @users = User.order_by_role_and_name
  end

  def show
    @user = User.find( params[ :id])
  # @bookings = @user.bookings.sort.paginate( :page => params[ :page])
  end

  def edit
    @user = User.find( params[ :id])
  end

  def update
    @user = User.find( params[ :id])
    case params[ :commit]
    when VALUE_BOOK_MORNING     then update_book_do( :morning)
    when VALUE_BOOK_AFTERNOON   then update_book_do( :afternoon)
    when VALUE_UNBOOK_MORNING   then update_unbook_do( :morning)
    when VALUE_UNBOOK_AFTERNOON then update_unbook_do( :afternoon)
    else
      if @user.update_attributes( params[ :user])
        flash[ :success] = "Uppgifterna sparade"
        log_in @user  # because remember_token has been reset
        redirect_to court_days_path
      else
        render 'edit'
      end
    end
  end

  def enable
    @user = User.find( params[ :id])
    if @user.update_attribute :role, "normal"
      flash[ :success] = "Användare #{ @user.name}, #{ @user.email} aktiverad"
    else
      flash[ :error] =
        "Användare #{ @user.name}, #{ @user.email} kunde inte aktiveras"
    end
    redirect_to :users
  end

  def destroy
    destroyed = User.find( params[ :id])
    email = destroyed.email
    destroyed.destroy
    flash[ :success] = "User #{ email} destroyed."
    redirect_to users_url
  end

  def update_book_do( session)
    @user.bookings.create! :court_day_id => params[ :court_day],
                           :session => session
    back_to_court_days
  end
  private :update_book_do

  def update_unbook_do( session)
    @user.booked?( CourtDay.find( params[ :court_day]), session).destroy
    back_to_court_days
  end
  private :update_unbook_do
end

