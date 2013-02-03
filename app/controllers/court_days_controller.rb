class CourtDaysController < ApplicationController

   before_filter :logged_in_user
   before_filter :admin_user, :only => :update

  def index
    collect_court_days
  end

  def update
    @ajl_debug = params
    updated_date = params[ :id]
    @court_day = CourtDay.find_by_date( updated_date)
    if @court_day
      update_or_destroy
    else
      create
    end
    collect_court_days
    render :index
  end

  def collect_court_days
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

  def update_or_destroy
    updated = params_to_court_day
    if updated.something_to_do?
      if [ @court_day.morning, @court_day.afternoon, @court_day.notes] !=
           [ updated.morning, updated.afternoon, updated.notes]
        @court_day.morning = updated.morning
        @court_day.afternoon = updated.afternoon
        @court_day.notes = updated.notes
        @court_day.save
      end
    else
      @court_day.destroy
      @court_day = nil
    end
  end

  def create
    @court_day = params_to_court_day
    @court_day.save if @court_day.something_to_do?
  end

  # params[ :id] is not the DB id
  def params_to_court_day
    CourtDay.new( :date => params[ :id], :morning => params[ :morning],
      :afternoon => params[ :afternoon], :notes => params[ :notes])
  end

=begin
    @court_day = CourtDay.find( params[ :court_day])
    @court_day = CourtDay.new( params[ :court_day])
    if @court_day.save
      flash[ :success] = "Ny rättegångsdag"
      redirect_to @court_day
    else
      render 'new'
    end
  end

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

