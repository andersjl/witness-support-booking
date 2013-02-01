class CourtDaysController < ApplicationController

   before_filter :logged_in_user
   before_filter :admin_user, :only => [ :edit, :update]

  def index
    begin
      chosen_date = Date.parse( params[ :start_date])
    rescue
      chosen_date = Date.today
    end
    case params[ :commit]
    when ::LAST_WEEK_LABEL then chosen_date -= 7
    when ::NEXT_WEEK_LABEL then chosen_date += 7
    end
    @start_date = chosen_date - (chosen_date.cwday - 1)  # Mon = 0, Sun = 6
    defined_days = CourtDay.find :all,
                                 :conditions =>
                                   [ "date >= ? and date < ?",
                                     @start_date, @start_date + 14]
    @court_days = 14.times.collect do |n|
      if defined_days.first && defined_days.first.date == @start_date + n
        defined_days.shift
      else
        CourtDay.new :date => @start_date + n, :morning => 0, :afternoon => 0
      end
    end
  end

  def edit
    @court_day = CourtDay.find_by_date( params[ :id]) ||
                   CourtDay.new( :date => params[ :id],
                                 :morning => 0, :afternoon => 0)
  end

=begin
  def create
    @court_day = CourtDay.new( params[ :court_day])
    if @court_day.save
      flash[ :success] = "Ny rättegångsdag"
      redirect_to @court_day
    else
      render 'new'
    end
  end

  def update
    if @court_day.update_attributes( params[ :court_day])
      flash[ :success] = "Ändringar sparade"
      redirect_to @court_day
    else
      render 'edit'
    end
  end

  def correct_user
    @user = CourtDay.find( params[ :id])
    redirect_to( root_path) unless current_user?( @user)
  end
  private :correct_user
=end

=begin
  def logged_in_user
    store_location
    redirect_to log_in_url, :notice => "Logga in först" unless logged_in?
  end
  private :logged_in_user
  
  def admin_user
    redirect_to( root_path) unless current_user.admin?
  end
  private :admin_user
=end
end

