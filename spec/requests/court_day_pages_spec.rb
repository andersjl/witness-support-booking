require "spec_helper"

describe "CourtDay pages" do

  subject{ page}

  describe "index" do
    require "app/helpers/application_helper"
    include ApplicationHelper

    before do
      @user = create_test_user( :name => "Normal",
                                :email => "normal@exempel.se")
      log_in @user
      @court_day = create_test_court_day :date => Date.today + 5,
                                         :morning => 0, :afternoon => 3,
                                         :notes => "hejsan hoppsan"
      visit court_days_path
    end

    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | Rondningar")}
    it{ should have_selector( "h1", :text => "Rondningar")}
    it{ should_not have_content( Date.today - 7)}
    it{ should have_content( Date.today - (Date.today.cwday - 1))}
    it{ should have_content( Date.today)}
    it{ should have_content( Date.today + 7)}
    it{ should_not have_content( Date.today + 14)}
    it{ should have_content( @court_day.date)}
    # this test fails on linebreaks!!
    it{ should have_content( @court_day.notes)}

    it "has no edit button for any Court Day" do
      first_date = Date.today - (Date.today.cwday - 1)
      14.times{ |n| should_not have_selector( "table tr td form input",
                                              :id => first_date + n)}
    end

    context "when going one week back" do
      before{ click_button "Förra veckan"}
      it{ should_not have_content( Date.today - 14)}
      it{ should have_content( Date.today - 7)}
      it{ should have_content( Date.today)}
      it{ should_not have_content( Date.today + 7)}
    end

    context "when going one week forward" do
      before{ click_button "Nästa vecka"}
      it{ should_not have_content( Date.today)}
      it{ should have_content( Date.today + 7)}
      it{ should have_content( Date.today + 14)}
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

    context "when admin" do

      before do
        @admin = create_test_user( :name => "Admin",
                                   :email => "admin@exempel.se",
                                   :admin => true)
        visit log_in_path
        fill_in "E-post",   :with => @admin.email
        fill_in "Lösenord", :with => @admin.password
        click_button "Logga in"
        visit court_days_path
      end

      it "has edit link for each Court Day" do
        first_date = Date.today - (Date.today.cwday - 1)
        14.times{ |n| should have_link( "Ändra", :href => edit_court_day_path( first_date + n))}
      end

      context "clicking Court Day edit link" do
        before{ click_link( "edit-#{ @court_day.date}")}
        it{ should have_selector(
            "title", :text => "Bokning av vittnesstöd | #{ @court_day.date}")}
        it{ should have_selector(
            "h1", :text => "Rättegångsdag #{ @court_day.date}")}
      end
    end
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

