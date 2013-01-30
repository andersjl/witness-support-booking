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
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
    @user = User.find( params[ :id])
  end

  def update
    @user = User.find( params[ :id])
    if @user.update_attributes( params[ :user])
      flash[ :success] = "Uppgifterna sparade"
      log_in @user
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    destroyed = User.find( params[ :id])
    email = destroyed.email
    destroyed.destroy
    flash[ :success] = "User #{ email} destroyed."
    redirect_to users_url
  end

=begin
  def logged_in_user
    if logged_in?
      forget_return_to
    else
      store_return_to
      redirect_to log_in_url, :notice => "Logga in först"
    end
  end
  private :logged_in_user

  def correct_user
    @user = User.find( params[ :id])
    redirect_to( root_path) unless current_user?( @user)
  end
  private :correct_user
  
  def admin_user
    redirect_to( root_path) unless current_user.admin?
  end
  private :admin_user
=end
end

