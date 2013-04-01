require "spec_helper"

describe "Authentication pages" do

  subject{ page}

  describe "log_in page" do
    before{ visit log_in_path}

    it{ should have_selector( "h1", :text => t( "general.log_in"))}
    it{ should have_selector( "title",
          text: "#{ t( 'general.application')} | #{ t( 'general.log_in')}")}
  end

  describe "log_in" do

    def self.test_log_in( role)

      context role do

        before do
          @user = create_test_user :court => Court.find_by_name( "Domstol 1"),
                                   :email => "#{ role}@example.com",
                                   :name => role.capitalize,
                                   :role => role,
                                   :password => "vittne"
          visit log_in_path
          select "Domstol 1", :from => "session_court_id"
          fill_in "session_email", :with => "#{ role}@example.com"
          fill_in "session_password", :with => "vittne"
          click_button t( "general.log_in")
        end

        if role != "disabled"
          it{ should have_selector(
            "title", :text => "#{ t( "general.application")} | Rondningar")}
        end
        it{ should have_link( @user.court.name, :href => @user.court.link)}
        it{ should have_link( "Logga ut", :href => log_out_path)}
        it{ should_not have_link( "Logga in", :href => log_in_path)}

        context "followed by log out" do
          before{ click_link "Logga ut"}
          it{ should have_link( "Logga in")}
        end
      end
    end

    before{ visit log_in_path}

    context "with invalid information" do
      before{ click_button "Logga in"}
      it{ should have_selector( "title",
            text: "#{ t( 'general.application')} | #{ t( 'general.log_in')}")}
      it{ should have_selector(
           "div.alert.alert-error", :text => t( "sessions.create.error"))}
      describe "after visiting another page" do
        before{ click_link t( "general.application")}
        it{ should_not have_selector( "div.alert.alert-error")}
      end
    end

    context "with valid information" do
      before{ create_test_court :name => "Domstol", :count => 3}
      USER_ROLES.each{ |role| test_log_in role}
    end
  end
end

