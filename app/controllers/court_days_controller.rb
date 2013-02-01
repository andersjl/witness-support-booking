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

=begin
<div id="court-days">
  <div class="row heading">
    <div class="offset1 span1">Datum</div>
    <div class="span2">Förmiddag</div>
    <div class="span2">Eftermiddag</div>
    <div class="span6">Noteringar</div>
  </div>
  <div class="row court-day">
    <div class="span1 weekday">Må</div>
    <div class="span1">2013-01-28</div>
    <div class="span2">NN</div>
    <div class="span2">2 kvar att boka</div>
    <div class="span6">Noteringar av diverse slag</div>
  </div>
  <div class="row court-day last">
    <div class="span1 weekday">Ti</div>
    <div class="span1">2013-01-29</div>
    <div class="span2">
      <div class="row">
        <div class="span2">NN</div>
      </div>
      <div class="row">
        <div class="span2">NN</div>
      </div>
    </div>
    <div class="span2">
      <div class="row">
        <div class="span2">2 kvar att boka</div>
      </div>
    </div>
    <div class="span6">Noteringar av diverse slag dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfas dfasfsadfasf sdfasffffffffffffffffffff dfasfsadfasf sdfasf</div>
  </div>
</div>

_court_day.html.erb
<%
  court_day_rows = [ 1, court_day.morning, court_day.afternoon].max
  1.upto( court_day_rows) do |row|
%>
  <tr id="display-<%= court_day.date %>">
    <% if row == 1 %>
      <%= td_rowspan( court_day_rows, weekday( court_day.date)).html_safe %>
      <%= td_rowspan( court_day_rows, court_day.date).html_safe %>
    <% end %>
    <% if row <= court_day.morning_taken %>
      <td><%= court_day.morning_taken( row - 1) %></td>
    <% else %>
      <%= render :partial => "unbooked_row",
                 :locals => { :row => row,
                              :taken => court_day.morning_taken,
                              :sessions => court_day.morning,
                              :max => court_day_rows} %>
    <% end %>
    <% if row <= court_day.afternoon_taken %>
      <td><%= court_day.afternoon_taken( row - 1) %></td>
    <% else %>
      <%= render :partial => "unbooked_row",
                 :locals => { :row => row,
                              :taken => court_day.afternoon_taken,
                              :sessions => court_day.afternoon,
                              :max => court_day_rows} %>
    <% end %>
    <% if row == 1 %>
      <%= td_rowspan( court_day_rows, h( court_day.notes).gsub( "\n", "<br/>")
                    ).html_safe %>
      <% if current_user.admin? %>
        <td><%= link_to "Ändra", edit_court_day_path( court_day.date),
                        :method => "get", :id => "edit-#{ court_day.date}"
            %></td>
      <% end %>
    <% end %>
  </tr>
<% end %>
=end

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

