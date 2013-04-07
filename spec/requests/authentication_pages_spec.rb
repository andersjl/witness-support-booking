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
          select "Domstol 1", :from => "user_session_court_id"
          fill_in "user_session_email", :with => "#{ role}@example.com"
          fill_in "user_session_password", :with => "vittne"
          click_button t( "general.log_in")
        end

        if role != "disabled"
          it{ should have_selector( "title",
                text: "#{ t( 'general.application')
                        } | #{ t( 'court_days.index.title')}")}
        end
        it{ should have_link( @user.court.name, :href => @user.court.link)}
        it{ should have_link( t( "general.log_out"), :href => log_out_path)}
        it{ should_not have_link( t( "general.log_in"), :href => log_in_path)}

        context "followed by log out" do
          before{ click_link t( "general.log_out")}
          it{ should have_link( t( "general.log_in"))}
        end
      end
    end

    before{ visit log_in_path}

    context "with invalid information" do
      before{ click_button t( "general.log_in")}
      it{ should have_selector( "title",
            text: "#{ t( 'general.application')} | #{ t( 'general.log_in')}")}
      it{ should have_selector(
           "div.alert.alert-error", :text => t( "user_sessions.create.error"))}
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

  describe "spoof" do

    before do
      create_test_court :name => "Domstol", :count => 3
      @spoofer_court = Court.all.sample
      @spoofed_court = rand( 2) == 0 ? @spoofer_court :
                                       (Court.all - [ @spoofer_court]).sample
    end

    USER_ROLES.each do |spoofer_role|

      context "as #{ spoofer_role}" do

        before do
          @spoofer = create_test_user(
                       court:    @spoofer_court,
                       email:    "spoofer.#{ spoofer_role}@example.com",
                       name:     "Spoofer #{ spoofer_role.capitalize}",
                       role:     spoofer_role,
                       password: "spoofer")
          visit log_in_path
          select @spoofer_court.name, from: "user_session_court_id"
          fill_in "user_session_email",    with: @spoofer.email
          fill_in "user_session_password", with: @spoofer.password
          click_button t( "general.log_in")
        end

        USER_ROLES.each do |spoofed_role|

          should_work = spoofer_role == "master" && spoofed_role != "master"

          context "spoofing #{ spoofed_role}" do

            def check_logged_in( user, spoofer = nil)
              visit edit_user_path( user)
              page.should have_selector(
                  "input[id='user_name']", value: user.name)
              page.should_not have_selector(
                  "input[disabled='disabled'][id='user_name']")
            end

            before do
              @spoofed = create_test_user(
                           court:    @spoofed_court,
                           email:    "spoofed.#{ spoofed_role}@example.com",
                           name:     "Spoofed #{ spoofed_role.capitalize}",
                           role:     spoofed_role,
                           password: "spoofed")
              visit log_in_path
              select @spoofed_court.name, from: "user_session_court_id"
              fill_in "user_session_email",    with: @spoofed.email
              # do NOT fill in password!
              click_button t( "general.log_in")
            end

            if should_work then
              specify( "succeeds"){ check_logged_in( @spoofed)}
            else
              specify( "fails"){ check_logged_in( @spoofer)}
            end

            context "followed by log out" do
              before{ click_link t( "general.log_out")}
              if should_work then
                specify( "still logged in"){ check_logged_in( @spoofer)}
              else
                specify( "logged out"){ page.should have_link(
                                     t( "general.log_in"), href: log_in_path)}
              end
            end
          end
        end
      end
    end
  end
end

