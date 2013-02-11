require "spec_helper"
require "app/helpers/application_helper"
include ApplicationHelper
include SessionsHelper

describe "CourtDay index" do

  subject{ page}

  before do
    @monday = lambda{ |d| d - (d.cwday - 1)}.call( Date.today + 2)
    @cd = create_test_court_day :date => @monday + rand( 5),
      :morning => 1, :afternoon => 3, :notes => "hejsan hoppsan"
    @cd_id = "court-day-#{ @cd.date}"
    @booked_user = create_test_user :name => "Berit Bokad",
      :email => "bokad@example.com"
    @booked_user.book!( @cd, :afternoon)
  end

  shared_examples_for "on court_days index page" do
    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | Rondningar")}
    it{ should have_selector( "h1", :text => "Rondningar")}
  end

  shared_examples_for "any user" do

    def test_dates( monday)
      (7 * (WEEKS_P_PAGE + 2) + 1).times do |n|
        date = monday + n - 7
        yield date, n % 7 < 5 && 6 < n && n < 7 * (WEEKS_P_PAGE + 1)
      end
    end

    it "has #{ WEEKS_P_PAGE} weeks starting this monday" do
      test_dates( @monday) do |date, ok|
        if ok
          should have_content( date)
        else
          should_not have_content( date)
        end
      end
    end

    it{ within( :id, @cd_id){ should have_content( weekday( @cd.date))}}
    it{ within( :id, @cd_id){ should have_content( @cd.date)}}
    it{ within( :id, @cd_id){ should have_content( @booked_user.name)}}
    it{ within( :id, @cd_id){ should have_content( @cd.notes)}}  # no \n!!
    it{ within( :id, @cd_id){
      should_not have_selector( "input[value='#{ VALUE_UNBOOK_MORNING}']")}}
    it{ within( :id, @cd_id){
      should_not have_selector( "input[value='#{ VALUE_UNBOOK_AFTERNOON}']")}}

    context "going one week back" do
      before{ click_button VALUE_LAST_WEEK}
      it "has #{ WEEKS_P_PAGE} weeks starting monday last week" do
        test_dates( @monday - 7) do |date, ok|
          if ok
            should have_content( date)
          else
            should_not have_content( date)
          end
        end
      end
    end

    context "going one week forward" do
      before{ click_button VALUE_NEXT_WEEK}
      it "has #{ WEEKS_P_PAGE} weeks starting monday next week" do
        test_dates( @monday + 7) do |date, ok|
          if ok
            should have_content( date)
          else
            should_not have_content( date)
          end
        end
      end
    end

    context "setting the date" do
      before do
        @new_start_date = @monday + 4711 + rand( 7)
        fill_in "start_date", :with => @new_start_date
        click_button "OK"
      end
      it "display should start monday" do
        should have_content( @new_start_date - (@new_start_date.cwday - 1))
      end
    end
  end

  context "when not admin" do

    shared_examples_for "unbooked" do
      it_behaves_like "on court_days index page"
      it{ should_not have_selector( "select")}
      it{ should_not have_selector( "textarea")}
      it{ should have_content( "(2 kvar)")}
      it{ within( :id, @cd_id){
        should_not have_selector( "input[value='#{ VALUE_SAVE}']")}}
      it{ within( :id, @cd_id){
        should have_selector( "input[value='#{ VALUE_BOOK_MORNING}']")}}
      it{ within( :id, @cd_id){
        should have_selector( "input[value='#{ VALUE_BOOK_AFTERNOON}']")}}
    end

    before do
      @user = create_test_user( :name => "Normal",
                                :email => "normal@exempel.se")
      fake_log_in @user
    end

    it_behaves_like "any user"
    it_behaves_like "unbooked"

    context "when there are deactivated users" do
      before do
        dis1, dis2, dis3 = create_test_user :count => 3, :role => "disabled"
        visit court_days_path
      end
      it{ within( "div.row.heading"){ should_not have_link( "3 nya att aktivera")}}
    end

    context "booking" do

      def login_other_user
        @other = create_test_user( :name => "En Annan",
                                   :email => "en.annan@exempel.se")
        fake_log_in @other
      end

      shared_examples_for "any booking button click" do

        it_behaves_like "on court_days index page"
        it{ within( :id, @cd_id){ should have_content( @user.name)}}
        it{ within( :id, @cd_id){
          should_not have_selector( "input[value='#{ @value_book}']")}}
        it{ within( :id, @cd_id){
          should have_selector( "input[value='#{ @value_unbook}']")}}

        context "when unbooked" do
          before{ within( :id, @cd_id){ click_button @value_unbook}}
          it_behaves_like "unbooked"
        end
      end

      shared_examples_for "any other user" do
        it_behaves_like "on court_days index page"
        it{ within( :id, @cd_id){
          should_not have_selector( "input[value='#{ @value_unbook}']")}}
      end

      context "last" do

        before do
          within( :id, @cd_id){ click_button VALUE_BOOK_MORNING}
          @value_book = VALUE_BOOK_MORNING
          @value_unbook = VALUE_UNBOOK_MORNING
        end

        it_behaves_like "any booking button click"

        context "switch user" do
          before{ login_other_user}
          it_behaves_like "any other user"
          it{ within( :id, @cd_id){
            should_not have_selector( "input[value='#{ @value_book}']")}}
        end
      end

      context "not last" do

        before do
          within( :id, @cd_id){ click_button VALUE_BOOK_AFTERNOON}
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
    end
  end

  context "when admin" do

    before do
      @admin = create_test_user( :name => "Admin",
                                 :email => "admin@exempel.se",
                                 :role => "admin")
      fake_log_in @admin
    end

    it_behaves_like "on court_days index page"
    it_behaves_like "any user"

    it "has input controls for each Court Day" do
      (5 * WEEKS_P_PAGE).times do |n|
        weeks, days = n.divmod( 5)
        within( :id, "court-day-#{ @monday + 7 * weeks + days}") do
          should have_selector( "select")
          should have_selector( "textarea")
          should have_selector( "input[value='#{ VALUE_SAVE}']")
        end
      end
    end
    
    context "changing and saving" do

      before do
        @morning = "1"
        @afternoon = "2"
        @first_line = "<- blanka radbrytning->"
        @notes = "  #{ @first_line}\nnästa rad"
        begin
          @changed_date = @monday + rand( 5)
        end while @changed_date == @cd.date
        @changed_id = "court-day-#{ @changed_date}"
        within( :id, @changed_id) do
          select( @morning, :from => "morning-#{ @changed_date}")
          select( @afternoon, :from => "afternoon-#{ @changed_date}")
          fill_in( "notes-#{ @changed_date}", :with => @notes)
          click_button( VALUE_SAVE)
        end
        @changed_obj = CourtDay.find_by_date( @changed_date)
      end

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

    context "when there are deactivated users" do
      before do
        dis1, dis2, dis3 = create_test_user :count => 3, :role => "disabled"
        visit court_days_path
      end
      it{ within( "div.row.heading"){
            should have_link( "3 nya att aktivera", :href => users_path)}}
    end
  end
end

