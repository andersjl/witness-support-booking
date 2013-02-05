require "spec_helper"

describe "CourtDay pages" do

  subject{ page}

  describe "index" do
    require "app/helpers/application_helper"
    include ApplicationHelper

    before do
      @court_day = create_test_court_day :date => Date.today + 5,
                                         :morning => 0, :afternoon => 3,
                                         :notes => "hejsan hoppsan"
      @first_date = Date.today - (Date.today.cwday - 1)
    end

    shared_examples_for "any user" do
      it{ should have_selector(
        "title", :text => "Bokning av vittnesstöd | Rondningar")}
      it{ should have_selector( "h1", :text => "Rondningar")}
      it{ should_not have_content( Date.today - 7)}
      it{ should have_content( Date.today - (Date.today.cwday - 1))}
      it{ should have_content( Date.today)}
      it{ should have_content( Date.today + 7)}
      it{ should_not have_content( Date.today + 7 * WEEKS_P_PAGE)}
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
        before{ click_button "Förra veckan"}
        it{ should_not have_content( Date.today - 7 * WEEKS_P_PAGE)}
        it{ should have_content( Date.today - 7)}
        it{ should have_content( Date.today)}
        it{ should_not have_content( Date.today + 7)}
      end

      context "when going one week forward" do
        before{ click_button "Nästa vecka"}
        it{ should_not have_content( Date.today)}
        it{ should have_content( Date.today + 7)}
        it{ should have_content( Date.today + 7 * WEEKS_P_PAGE)}
        it{ should_not have_content( Date.today + 21)}
      end

      context "when setting the date" do
        before do
          @new_start_date = Date.today + 4711
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
        (7 * WEEKS_P_PAGE).times do |n|
          within( :id, "court-day-#{ @first_date + n}") do
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
          @changed_date = @first_date + 7
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

=begin
      context "clicking Court Day edit link" do
        before{ click_link( "edit-#{ @court_day.date}")}
        it{ should have_selector(
            "title", :text => "Bokning av vittnesstöd | #{ @court_day.date}")}
        it{ should have_selector(
            "h1", :text => "Rättegångsdag #{ @court_day.date}")}
      end
    end
=end
  end

=begin
  describe "edit" do

    before do
      @court_day = create_test_court_day :date => Date.today + 5,
                                         :morning => 0, :afternoon => 3,
                                         :notes => "hejsan\nhoppsan"
      @admin = create_test_user( :name => "Admin",
                                 :email => "admin@exempel.se",
                                 :admin => true)
      visit log_in_path
      fill_in "E-post",   :with => @admin.email
      fill_in "Lösenord", :with => @admin.password
      click_button "Logga in"
      visit edit_court_day_path( @court_day.date)
    end

    it{ should have_selector(
        "title", :text => "Bokning av vittnesstöd | #{ @court_day.date}")}
    it{ should have_selector(
        "h1", :text => "Rättegångsdag #{ @court_day.date}")}

    context "with nothing to do" do
      before do
        fill_in "Förmiddag", :with => 0
        fill_in "Eftermiddag", :with => 0
        fill_in "Noteringar", :with => ""
        click_button "Spara ändringar"
      end

      it "the Court Day is deleted" do
        CourtDay.find_by_date( @court_day.date).should be_nil
      end
    end
  end
=end
end

