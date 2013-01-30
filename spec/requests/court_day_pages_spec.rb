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
    it{ should have_content( @court_day.notes)}

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
  end
end

