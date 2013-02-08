class UsersController < ApplicationController

  before_filter :logged_in_user, :only => [ :index, :edit, :update, :destroy]
  before_filter :correct_user, :only => [ :edit, :update]
  before_filter :admin_user, :only => :destroy

  def new
    @user = User.new
  end

  def show
    @user = User.find( params[ :id])
  # @bookings = @user.bookings.sort.paginate( :page => params[ :page])
  end

  def index
    @users = User.paginate( :page => params[ :page])
  end

  def create
    @user = User.new( params[ :user])
    if @user.save
      log_in @user
      flash[ :success] = "Välkommen att boka!"
      redirect_to court_days_path
    else
      render 'new'
    end
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
        log_in @user
        redirect_to court_days_path
      else
        render 'edit'
      end
    end
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
  private :update_book_do
end

