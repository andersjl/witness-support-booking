require "spec_helper"

describe "User pages" do

  subject{ page}

  describe "sign_up process" do

    before{ visit sign_up_path}
    let( :submit){ "Registrera ny användare"}

    it{ should have_selector( "h1", :text => "Ny användare")}
    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | Ny användare")}

    context "with invalid information" do
      it "should not create a user" do
        expect{ click_button submit}.not_to change( User, :count)
      end
    end

    context "with valid information" do

      before do
        fill_in "Namn",              :with => "Example User"
        fill_in "E-post",            :with => "user@example.com"
        fill_in "Välj lösenord",     :with => "foobar"
        fill_in "Bekräfta lösenord", :with => "foobar"
      end

      it "should create a user" do
        expect{ click_button submit}.to change( User, :count).by( 1)
      end

      context "after saving the user" do
        before do
          click_button submit
          @user = User.find_by_email( "user@example.com")
        end
        it{ @user.should_not be_enabled}
        it{ should_not have_selector(
          "title", :text => "Bokning av vittnesstöd | ")}
        it{ should have_content(
    "Du kommer att få ett mejl till user@example.com när du kan börja boka!")}
        it{ should have_selector( "div.alert.alert-success",
                                  :text => "Välkommen #{ @user.name}")}
        it{ should_not have_link( "Rondningar")}
        it{ should_not have_link( "Användare")}
        it{ should_not have_link( "Mina uppgifter")}
        it{ should have_link( "Ändra #{ @user.name}",
                               :href => edit_user_path( @user))}
        it{ should have_link( "Logga ut", :href => log_out_path)}
        it{ should_not have_link( "Logga in")}
        it "should send an email to admin"

        context "when enabled by admin" do

          before do
            @admin = create_test_user :role => "admin"
            fake_log_in @admin
            visit users_path
            within( "li#user-#{ @user.id}"){ click_link( "Aktivera")}
          end
          
          it{ @user.reload.should be_enabled}
          it "should send an email to the enabled user"

          context "flashes success" do
            it{ should have_selector( "div.alert.alert-success", :content => @user.name)}
            it{ within( "div.alert.alert-success"){ should have_content( @user.name)}}
            it{ within( "div.alert.alert-success"){ should have_content( @user.email)}}
          end
        end
      end
    end
  end

  describe "index" do

    before do
      @user = create_test_user( :name => "Normal",
                                :email => "normal@exempel.se")
      fake_log_in @user
      visit users_path
    end

    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | Användare")}
    it{ should have_selector( "h1", :text => "Alla användare")}

    describe "pagination" do

      before( :all){ create_test_user :count => 30}
      after( :all){ User.delete_all}
      it "should list each user" do
        User.order_by_role_and_name.each do |user|
          page.should have_selector( "li", :text => user.name)
        end
      end
    end

    describe "enable/delete/rescue" do

      it{ should_not have_link( "Ta bort")}
      it{ should_not have_link( "Aktivera")}
      it "has no change password link"

      context "as an admin user" do
        before do
          @admin = create_test_user :role => "admin", :name => "Admin",
            :email => "anders1lindeberg@gmail.com"
          fake_log_in @admin
          visit users_path
        end

        it{ within( "li#user-#{ @user.id}"){
              should have_link( "Ta bort", :href => user_path( User.first))}}
        it "should be able to delete another user" do
          expect{ click_link( "Ta bort")}.to change( User, :count).by( -1)
        end
        it "should be able to deactivate another user"
        it{ should_not have_link( "Ta bort", :href => user_path( @admin))}
        it "can set new user password"

        context "when a user is disabled" do
          before do
            @new_user = create_test_user :role => "disabled"
            visit users_path
          end
          it{ within( "li#user-#{ @new_user.id}"){
                should have_link( "Aktivera", :href => enable_user_path( @new_user))}}
        end
      end
    end
  end

  describe "show" do

    before do
      @user = create_test_user
      fake_log_in @user
      visit user_path( @user)
    end

    it{ should have_selector( "h1",    :text => @user.name)}
    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | #{ @user.name}")}

    context "admin" do

      before do
        @user.update_attribute :role, "admin"
        fake_log_in @user
        visit user_path( @user)
      end

      it{ should have_link "Läs ut hela databasen till en fil", 
                           :href => database_path}
      it{ should have_link "RADERA HELA DATABASEN och läs in en fil",
                           :href => new_database_path}

      context "saving database" do
        # file content is tested with the new_database_path request
        before{ click_link "Läs ut hela databasen till en fil"}
        context "page.response_headers[ 'Content-Type']" do
          it{ page.response_headers[ "Content-Type"].should == "text/xml"}
        end
      end
    end
  end

  describe "edit" do

    before( :each) do
      visit log_in_path
      @user = create_test_user
      fake_log_in @user
      visit edit_user_path( @user)
    end

    describe "page" do
      it{ should have_selector( "h1",    :text => "Ändra #{ @user.name}")}
      it{ should have_selector(
        "title", :text => "Bokning av vittnesstöd | Ändra #{ @user.name}")}
    end

    describe "with invalid information" do
      before{ click_button "Spara ändringar"}
      it{ should have_content( "fel")}
    end

    describe "with valid information" do
      let( :new_name){ "Nytt Namn"}
      let( :new_email){ "ny@example.com"}
      before do
        fill_in "Namn", :with => new_name
        fill_in "E-post", :with => new_email
        fill_in "Lösenord", :with => @user.password
        fill_in "Bekräfta lösenord", :with => @user.password
        click_button "Spara ändringar"
      end

      it{ should have_selector(
        "title", :text => "Bokning av vittnesstöd | Rondningar")}
        it{ should have_selector( "div.alert.alert-success")}
        it{ should have_link( "Logga ut", :href => log_out_path)}
        specify{ @user.reload.name.should  == new_name}
        specify{ @user.reload.email.should == new_email}
    end
  end
end

