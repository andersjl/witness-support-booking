require "spec_helper"

describe "CourtDay pages" do

  subject{ page}

  describe "index" do
    require "app/helpers/application_helper"
    include ApplicationHelper

    before do
      @monday = lambda{ |d| d - (d.cwday - 1)}.call( Date.today + 2)
      @court_day = create_test_court_day :date => @monday + rand( 5),
        :morning => 0, :afternoon => 3, :notes => "hejsan hoppsan"
    end

    shared_examples_for "any user" do

      def test_dates( monday)
        (7 * (WEEKS_P_PAGE + 2) + 1).times do |n|
          date = monday + n - 7
          yield date, n % 7 < 5 && 6 < n && n < 7 * (WEEKS_P_PAGE + 1)
        end
      end

      it{ should have_selector(
        "title", :text => "Bokning av vittnesstöd | Rondningar")}
      it{ should have_selector( "h1", :text => "Rondningar")}
      it "has #{ WEEKS_P_PAGE} weeks starting this monday" do
        test_dates( @monday) do |date, ok|
          if ok
            should have_content( date)
          else
            should_not have_content( date)
          end
        end
      end
      it "has correct data" do
        within( :id, "court-day-#{ @court_day.date}") do
          should have_content( @court_day.date)
        # untestable as long as it is a random stub
        # unbooked = @court_day.afternoon - @court_day.afternoon_taken
        # should have_content( "#{ unbooked} kvar att boka") if unbooked > 0
          should have_content( @court_day.notes)  # fails on linebreaks!!
        end
      end

      context "when going one week back" do
        before{ click_button LAST_WEEK_LABEL}
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

      context "when going one week forward" do
        before{ click_button NEXT_WEEK_LABEL}
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

      context "when setting the date" do
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

      before do
        @user = create_test_user( :name => "Normal",
                                  :email => "normal@exempel.se")
        visit log_in_path
        fill_in "E-post",   :with => @user.email
        fill_in "Lösenord", :with => @user.password
        click_button "Logga in"
      end

      it_behaves_like "any user"

      it{ should_not have_selector( "select")}
      it{ should_not have_selector( "textarea")}
      it "has no save button" do
        lambda{ click_button "Spara"}.should raise_error 
      end
    end

    context "when admin" do

      before do
        @admin = create_test_user( :name => "Admin",
                                   :email => "admin@exempel.se",
                                   :admin => true)
        visit log_in_path
        fill_in "E-post",   :with => @admin.email
        fill_in "Lösenord", :with => @admin.password
        click_button "Logga in"
      end

      it_behaves_like "any user"

      it "has input controls for each Court Day" do
        (5 * WEEKS_P_PAGE).times do |n|
          weeks, days = n.divmod( 5)
          within( :id, "court-day-#{ @monday + 7 * weeks + days}") do
            should have_selector( "select")
            should have_selector( "textarea")
            lambda{ click_button "Spara"}.should_not raise_error
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
          end while @changed_date == @court_day.date
          @changed_id = "court-day-#{ @changed_date}"
          within( :id, @changed_id) do
            select( @morning, :from => "morning")
            select( @afternoon, :from => "afternoon")
            fill_in( "notes", :with => @notes)
            click_button( "Spara")
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
          # untestable as long as it is a random stub
          # [ "morning", "afternoon"].each ...
          # should have_content( "#{ unbooked} kvar att boka") if unbooked > 0
            should have_content( @first_line)
          end
        end
      end
    end
  end
end

