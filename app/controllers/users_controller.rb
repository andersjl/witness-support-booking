class UsersController < ApplicationController

   before_filter :signed_in_user, :only => [ :index, :edit, :update, :destroy]
   before_filter :correct_user, :only => [ :edit, :update]
   before_filter :admin_user, :only => :destroy

  def new
    @user = User.new
  end

  def show
    @user = User.find( params[ :id])
  end

  def index
    @users = User.paginate( :page => params[ :page])
  end

  def create
    @user = User.new( params[ :user])
    if @user.save
      sign_in @user
      flash[ :success] = "Välkommen att boka!"
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @user.update_attributes( params[ :user])
      flash[ :success] = "Uppgifterna sparade"
      sign_in @user
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

  def signed_in_user
    store_location
    redirect_to signin_url, :notice => "Logga in först" unless signed_in?
  end
  private :signed_in_user

  def correct_user
    @user = User.find( params[ :id])
    redirect_to( root_path) unless current_user?( @user)
  end
  private :correct_user
  
  def admin_user
    redirect_to( root_path) unless current_user.admin?
  end
end

