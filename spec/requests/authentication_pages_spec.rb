require "spec_helper"

describe "Authentication pages" do

  subject{ page}

  describe "log_in page" do
    before{ visit log_in_path}

    it{ should have_selector( "h1", :text => "Logga in")}
    it{ should have_selector(
      "title", :text => "#{ APPLICATION_NAME} | Logga in")}
  end

  describe "log_in" do
    
    before{ visit log_in_path}

    context "with invalid information" do
      before{ click_button "Logga in"}
      it{ should have_selector(
        "title", :text => "#{ APPLICATION_NAME} | Logga in")}
      it{ should have_selector( "div.alert.alert-error", :text => "Ogiltig")}
      describe "after visiting another page" do
        before{ click_link "Start"}
        it{ should_not have_selector( "div.alert.alert-error")}
      end
    end

    context "with valid information" do

      before do
        @user = create_test_user
        fake_log_in @user
      end

      it{ should have_selector(
        "title", :text => "#{ APPLICATION_NAME} | Rondningar")}
      it{ should have_link( "Rondningar", :href => court_days_path)}
      it{ should have_link( "Användare", :href => users_path)}
      it{ should have_link( "Logga ut", :href => log_out_path)}
      it{ should_not have_link( "Logga in", :href => log_in_path)}

      describe "followed by log out" do
        before{ click_link "Logga ut"}
        it{ should have_link( "Logga in")}
      end
    end
  end
end

