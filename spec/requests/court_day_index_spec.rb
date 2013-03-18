require "spec_helper"
require "app/helpers/application_helper"
include ApplicationHelper
include SessionsHelper

describe "CourtDay index" do

  def test_dates( date_in_week)
    (7 * (WEEKS_P_PAGE + 2) + 1).times do |n|
      date = CourtDay.monday( date_in_week) + n - 7
      show = n % 7 < 5 && 6 < n && n < 7 * (WEEKS_P_PAGE + 1)
      from_here_to_eternity = date >= Date.today
      yield date, show, from_here_to_eternity
    end
  end

  def create_future_date
    @tested_date = @cd.date + 21
    @tested_id = "court-day-#{ @tested_date}-morning"
    @future_cd = create_test_court_day :date => @tested_date
  end

  def visit_future_date
    within :id, "weekpicker-bottom" do
      fill_in "datepicker-bottom", :with => @tested_date
      click_on "OK"
    end
  end

  def create_and_visit_future_date
    create_future_date
    visit_future_date
  end

  def shows( date)
    should have_selector "div[id='court-day-#{ date}']"
  end

  subject{ page}

  before do
    @monday = CourtDay.monday( Date.today)
    first_date = @monday <= Date.today ? Date.today : @monday
    @n_changeable = 6 - first_date.cwday
    @cd = create_test_court_day :date => first_date + rand( @n_changeable),
      :morning => 1, :afternoon => 3, :notes => "tested notes"
    @cd_id = "court-day-#{ @cd.date}"
    @booked_user = create_test_user :name => "Berit Bokad",
                                    :email => "bokad@example.com"
    @booked_user.book!( @cd, :afternoon)
  end

  shared_examples_for "on court_days index page" do
    it{ should have_selector(
      "title", :text => "#{ APPLICATION_NAME} | Rondningar")}
    it{ should have_selector( "h1", :text => "Rondningar")}
  end

  shared_examples_for "any week" do

    it "has correct days" do
      test_dates( @tested_date) do |date, show, from_here_to_eternity|
        if show
          should have_content date
        else
          should_not have_content date
        end
      end
    end

    it "has controls from today on" do
      test_dates( @tested_date) do |date, show, from_here_to_eternity|
        within( :id, "court-day-#{ date}"){ should have_selector "form"
                                          } if show && from_here_to_eternity
      end
    end


    it "has no controls up to yesterday" do
      test_dates( @tested_date) do |date, show, from_here_to_eternity|
        within( :id, "court-day-#{ date}"){ should_not have_selector "form"
                                          } if show && !from_here_to_eternity
      end
    end
  end

  shared_examples_for "any user" do

    context "this week" do
      before{ @tested_date = @monday}
      it_behaves_like "any week"
    end

    it{ within( :id, @cd_id){ should have_content( @cd.date)}}
    it{ within( :id, "#{ @cd_id}-afternoon"
              ){ should have_content( @booked_user.name)}}
    it{ within( :id, @cd_id){ should have_content( @cd.notes)}}  # no \n!!
    it{ within( :id, @cd_id){
      should_not have_selector( "input[value='#{ VALUE_UNBOOK_MORNING}']")}}
    it{ within( :id, @cd_id){
      should_not have_selector( "input[value='#{ VALUE_UNBOOK_AFTERNOON}']")}}

    context "going one week back" do
      before do
        click_button VALUE_LAST_WEEK
        @tested_date = @monday - 7
      end
      it_behaves_like "any week"
    end

    context "going one week forward" do
      before do
        click_button VALUE_NEXT_WEEK
        @tested_date = @monday + 7
      end
      it_behaves_like "any week"
    end

    context "setting the date" do
      before do
        @new_start_date = @monday + 4711 + rand( 7)
        fill_in "start_date", :with => @new_start_date
        click_button "OK"
        @tested_date = CourtDay.monday @new_start_date
      end

      it_behaves_like "any week"

      context "switching user resets the date" do
        before do
          @other = create_test_user( :name => "En Annan",
                                     :email => "en.annan@exempel.se")
          fake_log_in @other
          @tested_date = @monday
        end
        it_behaves_like "any week"
      end
    end
  end

  shared_examples_for "any changed day" do
    # @morning, @afternoon, @notes, @first_line,
    # @changed_date, @changed_id, @changed_obj,

    it "model object has correct data" do
      @changed_obj.morning.should == @morning.to_i
      @changed_obj.afternoon.should == @afternoon.to_i
      @changed_obj.notes.should == @notes.strip
    end

    it "page has correct data" do
      within( :id, @changed_id) do
        should have_content( @changed_date)
        [ :morning, :afternoon].each do |session|
          should have_content( eval( "\"\#{ @#{ session}} kvar att boka\""))
          should have_content( @first_line)
        end
      end
    end
  end

  shared_examples_for "any court admin" do
    # @admin, @booked_user, @monday, @cd, @cd_id

    it_behaves_like "on court_days index page"
    it_behaves_like "any user"

    it "has input controls for each changeable Court Day" do
      (5 * WEEKS_P_PAGE).times do |n|
        weeks, days = n.divmod( 5)
        date = @monday + 7 * weeks + days
        if date >= Date.today
          within( :id, "court-day-#{ date}") do
            should have_selector( "select")
            should have_selector( "textarea")
            should have_selector(
              "input[value='#{ VALUE_SAVE} #{ day_of_week( date)}']")
            court_day = CourtDay.find_by_court_id_and_date( court_this, date)
            court_day && court_day.bookings.each do |booking|
              should have_link( booking.user.name,
                                :href => booking_path( booking))
            end
          end
        end
      end
    end

    context "changing and saving" do

      def change( date)
        @changed_date = date
        @changed_id = "court-day-#{ date}"
        within( :id, @changed_id) do
          select( @morning, :from => "morning-#{ date}")
          select( @afternoon, :from => "afternoon-#{ date}")
          fill_in( "notes-#{ date}", :with => @notes)
          click_button( "#{ VALUE_SAVE} #{ day_of_week( date)}")
        end
        @changed_obj =
          CourtDay.find_by_court_id_and_date( @admin.court.id, date)
      end

      before do
        @morning = "1"
        @afternoon = "2"
        @first_line = "<- blanka radbrytning->"
        @notes = "  #{ @first_line}\nnästa rad"
        if @n_changeable <= 1
          @first_date = @monday + rand( 5)  # untestable this week
        else
          begin
            @first_date = @monday + 5 - @n_changeable + rand( @n_changeable)
          end while @first_date == @cd.date
        end
      end

      context "this week, change and save" do
        if Date.today.cwday == 5
          specify{ pending "cannot test changing this week on a Friday"}
        else
          before{ change @first_date}
          it_behaves_like "any changed day"
        end
      end

      context "next week, change and save" do
        before do
          click_button VALUE_NEXT_WEEK
          change @first_date + 7
        end
        it_behaves_like "any changed day"
      end

      context "future date, change and save" do
        before do
          weeks, days = (5 + rand( 100)).divmod 5
          new_start_date = @monday + 7 * weeks + days
          fill_in "start_date", :with => new_start_date
          click_button "OK"
          change( CourtDay.monday( new_start_date) + rand( 5))
        end
        it_behaves_like "any changed day"
      end

      context "changing need below already booked" do
        it "should warn the booked by email"
      end
    end

    context "when there are deactivated users" do
      before do
        dis1, dis2, dis3 = create_test_user :count => 3, :role => "disabled"
        visit court_days_path
      end
      it{ within( "div.row.heading"){
            should have_link( "3 ny att aktivera", :href => users_path)}}
    end

    context "unbooking" do

      before do
        @booked_user.book!( @cd, :morning)
        visit court_days_path
      end

      it{ within( :id, "#{ @cd_id}-morning"
                ){ expect{ click_link( @booked_user.name)
                         }.to change( Booking, :count).by( -1)}}

      context "morning," do
        before{ within( :id, "#{ @cd_id}-morning"
                      ){ click_link( @booked_user.name)}}
        context "morning" do
          it{ within( :id, "#{ @cd_id}-morning"
                    ){ should_not have_content( @booked_user.name)}}
        end
        context "afternoon still" do
          it{ within( :id, "#{ @cd_id}-afternoon"
                    ){ should have_content( @booked_user.name)}}
        end
      end

      context "future" do

        before do
          create_future_date
          @booked_user.book!( @future_cd, :morning)
          visit_future_date
          within( :id, @tested_id){ click_link( @booked_user.name)}
        end

        it{ shows @tested_date}
        specify{ @booked_user.should_not be_booked( @future_cd, :morning)}
      end

      context "past" do
        it "is not possible"
      end
    end
  end

  context "when not admin" do

    shared_examples_for "unbooked" do
      it_behaves_like "on court_days index page"
      it{ should_not have_selector( "select")}
      it{ should_not have_selector( "textarea")}
      it{ should have_content( "(2 kvar)")}
      it{ within( :id, @tested_id){
        should_not have_selector( 
          "input[value='#{ VALUE_SAVE} #{ day_of_week( @cd.date)}']")}}
      it{ within( :id, @tested_id){
        should have_selector( "input[value='#{ VALUE_BOOK_MORNING}']")}}
      it{ within( :id, @tested_id){
        should have_selector( "input[value='#{ VALUE_BOOK_AFTERNOON}']")}}

      it "has no controls when nothing to book" do
        test_dates( @monday) do |date, show, ignore|
          if show
            if date != @cd.date
              within( :id, "court-day-#{ date}") do
                should_not have_selector( "input[value='#{ VALUE_BOOK_MORNING}']")
                should_not have_selector( "input[value='#{ VALUE_BOOK_AFTERNOON}']")
              end
            end
          else
            should_not have_selector( "div[id='court-day-#{ date}']")
          end
        end
      end
    end

    before do
      @user = create_test_user( :name => "Normal",
                                :email => "normal@exempel.se")
      fake_log_in @user
      @tested_id = @cd_id
    end

    it_behaves_like "any user"
    it{ within( :id, @cd_id){ should have_content( day_of_week( @cd.date))}}
    it_behaves_like "unbooked"

    context "when there are disabled users" do
      before do
        dis1, dis2, dis3 = create_test_user :count => 3, :role => "disabled"
        visit court_days_path
      end
      it{ within( "div.row.heading"){ should_not have_content( "aktivera")}}
    end

    context "booking" do

      def login_other_user
        @other = create_test_user( :name => "En Annan",
                                   :email => "en.annan@exempel.se")
        fake_log_in @other
      end

      shared_examples_for "any booking button click" do

        it_behaves_like "on court_days index page"
        it{ within( :id, @tested_id){ should have_content( @user.name)}}
        it{ within( :id, @tested_id){ should_not have_link( @user.name)}}
        it{ within( :id, @tested_id){
          should_not have_selector( "input[value='#{ @value_book}']")}}
        it{ within( :id, @tested_id){
          should have_selector( "input[value='#{ @value_unbook}']")}}
        it( "has (x kvar) also when booked"){ pending "Malin har bollen"}
        it "emphasizes overbooking"

        context "when unbooked" do
          before{ within( :id, @tested_id){ click_button @value_unbook}}
          it_behaves_like "unbooked"
        end
      end

      shared_examples_for "any other user" do
        it_behaves_like "on court_days index page"
        it{ within( :id, @tested_id){
          should_not have_selector( "input[value='#{ @value_unbook}']")}}
      end

      context "last" do

        before do
          @tested_id = @cd_id
          within( :id, @tested_id){ click_button VALUE_BOOK_MORNING}
          @value_book = VALUE_BOOK_MORNING
          @value_unbook = VALUE_UNBOOK_MORNING
        end

        it_behaves_like "any booking button click"

        context "switch user" do
          before{ login_other_user}
          it_behaves_like "any other user"
          it{ within( :id, @tested_id){
            should_not have_selector( "input[value='#{ @value_book}']")}}
        end
      end

      context "not last" do

        before do
          @tested_id = @cd_id
          within( :id, @tested_id){ click_button VALUE_BOOK_AFTERNOON}
          @value_book = VALUE_BOOK_AFTERNOON
          @value_unbook = VALUE_UNBOOK_AFTERNOON
        end

        it_behaves_like "any booking button click"

        context "switch user" do
          before{ login_other_user}
          it_behaves_like "any other user"
          it{ within( :id, @cd_id){
            should have_selector( "input[value='#{ @value_book}']")}}
        end
      end

      context "overbooked" do

        before do
          @cd.update_attribute :morning, 0
          within( :id, @cd_id){ click_button VALUE_BOOK_MORNING}
        end

        specify{ @cd.morning_bookings.count.should == 0}
        it{ should have_selector( "div.alert.alert-error")}
      end

      context "future" do

        before do
          create_and_visit_future_date
          within( :id, @tested_id){ click_button VALUE_BOOK_MORNING}
        end

        it{ shows @tested_date}
        it{ within( :id, @tested_id){ should_not have_selector(
              "input[value='#{ VALUE_BOOK_MORNING}']")}}
        it{ within( :id, @tested_id){
          should have_selector( "input[value='#{ VALUE_UNBOOK_MORNING}']")}}

        context "unbooking" do
          before{ within( :id, @tested_id
                        ){ click_button VALUE_UNBOOK_MORNING}}
          it{ shows @tested_date}
          it{ within( :id, @tested_id){ should have_selector(
                "input[value='#{ VALUE_BOOK_MORNING}']")}}
          it{ within( :id, @tested_id){ should_not have_selector(
                "input[value='#{ VALUE_UNBOOK_MORNING}']")}}
        end
      end
    end
  end

  context "other court user" do
    before do
      other = User.find_by_court_id court_other.id
      unless CourtDay.find_by_court_id_and_date court_other.id, @cd.date
        create_test_court_day :court => court_other, :date => @cd.date,
                              :notes => "Other notes"
      end
      fake_log_in other, "otheru"
    end
    it{ within( :id, @cd_id){ should_not have_content( @cd.notes)}}
  end

  context "when admin" do

    before do
      @admin = create_test_user( :name => "Admin",
                                 :email => "admin@exempel.se",
                                 :role => "admin")
      fake_log_in @admin
    end

    it_behaves_like "any court admin"
  end

  context "when master" do

    before do
      @admin = create_test_user( :name => "Master",
                                 :email => "master@exempel.se",
                                 :role => "master")
      fake_log_in @admin
    end

    it_behaves_like "any court admin"
  end
end

