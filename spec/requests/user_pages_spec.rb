require "spec_helper"

describe "User pages" do

  subject{ page}

  describe "sign_up process" do

    before{ visit sign_up_path}
    let( :submit){ "Registrera ny användare"}

    it{ should have_selector( "h1", :text => "Ny användare")}
    it{ should have_selector(
      "title", :text => "#{ APPLICATION_NAME} | Ny användare")}

    context "with invalid information" do
      it "should not create a user" do
        expect{ click_button submit}.not_to change( User, :count)
      end
    end

    context "with valid information" do

      before do
        fill_in "user_name",     :with => "Example User"
        fill_in "user_email",    :with => "user@example.com"
        fill_in "user_password", :with => "foobar"
        fill_in "user_password_confirmation", :with => "foobar"
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
          "title", :text => "#{ APPLICATION_NAME} | ")}
        it{ should have_content(
    "Du kommer att få ett mejl till user@example.com när du kan börja boka!")}
        it{ should have_selector( "div.alert.alert-success",
                                  :text => "Välkommen #{ @user.name}")}
        it{ should_not have_link( "Rondningar")}
        it{ should_not have_link( "Användare")}
        it{ should have_link( "Logga ut", :href => log_out_path)}
        it{ should_not have_link( "Logga in")}
        it "should send an email to admin"

        context "when enabled by admin" do

          before do
            @admin = create_test_user :email => "ad@min",
                                      :role => "admin", :name => "Admin"
            fake_log_in @admin
            visit users_path
            within( "li#user-#{ @user.id}"){ click_link( "Aktivera")}
          end
          
          it{ @user.reload.should be_enabled}
          it "should send an email to the enabled user"

          context "flashes success" do
            it{ should have_selector( "div.alert.alert-success",
                                      :content => @user.name)}
            it{ should have_selector( "div.alert.alert-success",
                                      :content => @user.email)}
          end
        end
      end
    end
  end

  describe "index" do
    
    shared_examples_for "any admin" do  # @disabl, @normal, @admin

      it{ within( "li#user-#{ @disabl.id}"
                ){ should have_link( "Sätt nytt lösenord",
                                     :href => edit_user_path( @disabl))}}
      it{ within( "li#user-#{ @normal.id}"
                ){ should have_link( "Sätt nytt lösenord",
                                     :href => edit_user_path( @normal))}}
      it{ within( "li#user-#{ @admin.id}"
                ){ should_not have_content( "lösenord")}}

      it{ within( "li#user-#{ @disabl.id}"){
            should have_link( "Ta bort", :href => user_path( @disabl))}}
      it{ within( "li#user-#{ @normal.id}"){
            should have_link( "Ta bort", :href => user_path( @normal))}}
      it{ within( "li#user-#{ @admin.id}"
                ){ should_not have_content( "Ta bort")}}
      it "delete another user" do
        within( "li#user-#{ @disabl.id}"){ expect{ click_link( "Ta bort")
                                         }.to change( User, :count).by( -1)}
        within( "li#user-#{ @normal.id}"){ expect{ click_link( "Ta bort")
                                         }.to change( User, :count).by( -1)}
      end

      it{ within( "li#user-#{ @disabl.id}"){ should have_link(
            "Aktivera", :href => enable_user_path( @disabl))}}
      it{ within( "li#user-#{ @normal.id}"
                ){ should_not have_content( "Aktivera")}}
      it{ within( "li#user-#{ @admin.id}"
                ){ should_not have_content( "Aktivera")}}
      it "enable a disabled user" do
        within( "li#user-#{ @disabl.id}"){ click_link( "Aktivera")}
        @disabl.reload.role.should == "normal"
      end
    end

    before do
      @user = create_test_user( :count => 3).choice
      fake_log_in @user
      visit users_path
    end

    it{ should have_selector(
      "title", :text => "#{ APPLICATION_NAME} | Användare")}
    it{ should have_selector( "h1", :text => "Alla användare")}
    it{ should_not have_content( "Sätt nytt lösenord")}
    it{ should_not have_content( "Ta bort")}
    it{ should_not have_content( "Dektivera")}
    it{ should_not have_content( "Aktivera")}
    it{ should_not have_content( "Bemyndiga")}

    context "when clicking a user" do
      before do
        @other = User.where( "id != ?", @user.id).choice
        click_link( @other.name)
      end
      it{ should have_selector(
            "title", :text => "#{ APPLICATION_NAME} | #{ @other.name}")}
    end
 
    it "lists each user with link" do
      User.order_by_role_and_name.each do |user|
        page.should have_selector( "li", :text => user.name)
        page.should have_link( user.name)
        page.should_not have_content( user.email)
      end
    end

    context "as admin" do

      before do
        @disabl = create_test_user :email => "dis@abl",
                                   :name => "Disabled", :role  => "disabled"
        @normal = @user
        @admin  = create_test_user :email => "ad@min",
                                   :name => "Admin",    :role  => "admin"
        fake_log_in @admin
        visit users_path
      end

      it_behaves_like "any admin"
    end
  end

  describe "show" do

    before do
      @user = create_test_user
      fake_log_in @user
      visit user_path( @user)
    end

    shared_examples_for "viewing any user" do
      it{ should have_selector( "h1",    :text => @shown.name)}
      it{ should have_selector(
        "title", :text => "#{ APPLICATION_NAME} | #{ @shown.name}")}
    end

    context "self" do
      before{ @shown = @user}
      it_behaves_like "viewing any user"
      it{ should have_content( @user.email)}
      it{ should have_link( "Ändra", :href => edit_user_path( @user))}
      it{ should_not have_content( "en fil")}
    end

    context "other user" do
      before do
        @other = create_test_user :name => "Other", :email => "ot@her"
        @shown = @other
        visit user_path( @other)
      end
      it_behaves_like "viewing any user"
      it{ should_not have_content( @other.email)}
      it{ should_not have_content( "en fil")}
    end

    context "admin" do

      before do
        @admin = create_test_user :name => "Ad Min",
                                  :email => "ad@min", :role => "admin"
        fake_log_in @admin
        visit user_path( @admin)
      end

      context "viewing self" do
        before{ @shown = @admin}
        it_behaves_like "viewing any user"
        it{ should have_content( @admin.email)}
        it{ should have_link "Läs ut hela databasen till en fil", 
                             :href => database_path}
        it{ should have_link "RADERA HELA DATABASEN och läs in en fil",
                             :href => new_database_path}
      end

      context "viewing other" do
        before do
          visit user_path( @user)
          @shown = @user
        end
        it_behaves_like "viewing any user"
        it{ should_not have_content( "en fil")}
      # below is not a requirement?
      # it{ should have_content( @shown.email)}
      # it{ should_not have_content( @shown.email)}
      end

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
 
    def self.admin_examples
      # @editor, @edited, @new_email, @new_name, @new_pw

      context "admin" do

        before do
          visit edit_user_path( @edited)
        end

        it_behaves_like "editing any user"

        context "changing other attributes" do

          before do
            @old_email    = @edited.email
            @old_name     = @edited.name
            fill_in "user_email",                 :with => @new_email
            fill_in "user_name",                  :with => @new_name
            fill_in "user_password",              :with => @new_pw
            fill_in "user_password_confirmation", :with => @new_pw
            click_button "Spara ändringar"
            @edited.reload
          end

          specify{ @edited.email.should     == @old_email}
          specify{ @edited.name.should      == @old_name}
        end

        context "changing password" do

          before do
            @old_email    = @edited.email
            @old_name     = @edited.name
            @old_pw       = @edited.password
            fill_in "Lösenord", :with => @new_pw
            fill_in "Bekräfta lösenord", :with => @new_pw
            click_button "Spara ändringar"
            @edited.reload
          end

          it{ should have_selector(
            "title", :text => "#{ APPLICATION_NAME} | Användare")}
          it{ within( "div.alert.alert-success"
                    ){ should have_content( "Lösenordet ändrat")}}
          specify "still logged in as admin" do
            click_link( @editor.name)
            should have_content( @editor.email)
          end
          it_behaves_like "password change"
          specify{ @edited.email.should     == @old_email}
          specify{ @edited.name.should      == @old_name}
        end
      end
    end

    before do
      @user = create_test_user
      @old_pw = @user.password
      @new_name = "Nytt Namn"
      @new_email = "ny@mejl"
      @new_pw = "nytt-lösen"
    end

    shared_examples_for "editing any user" do
      it{ should have_selector( "h1",    :text => "Ändra #{ @edited.name}")}
      it{ should have_selector(
        "title", :text => "#{ APPLICATION_NAME} | Ändra #{ @edited.name}")}
    end

    shared_examples_for "password change" do
      # @edited, @old_pw, @new_pw
      it "old password does not work" do
        fake_log_in @edited, @old_pw
        should have_selector( "title",
                              :text => "#{ APPLICATION_NAME} | Logga in")
        should have_selector( "div.alert.alert-error")
      end
      it "new password works" do
        fake_log_in @edited, @new_pw
        should have_selector( "title",
                              :text => "#{ APPLICATION_NAME} | Rondningar")
      end
    end

    context "yourself" do

      before do
        fake_log_in @user
        visit edit_user_path( @user)
        @edited = @user
      end

      it_behaves_like "editing any user"

      describe "with invalid password" do
        before{ click_button "Spara ändringar"}
        it{ should have_selector( "div.alert.alert-error")}
      end
 
      describe "email collision" do
        before do
          create_test_user :email => @new_email
          fill_in "user_email",                 :with => @new_email
          fill_in "user_name",                  :with => @new_name
          fill_in "user_password",              :with => @new_pw
          fill_in "user_password_confirmation", :with => @new_pw
          click_button "Spara ändringar"
        end
        it{ should have_selector( "div.alert.alert-error")}
      end

      describe "with valid information" do

        before do
          fill_in "user_email",                 :with => @new_email
          fill_in "user_name",                  :with => @new_name
          fill_in "user_password",              :with => @new_pw
          fill_in "user_password_confirmation", :with => @new_pw
          click_button "Spara ändringar"
          @user.reload
          @edited = @user
        end

        it_behaves_like "password change"
        it{ should have_selector(
          "title", :text => "#{ APPLICATION_NAME} | Rondningar")}
        it{ within( "div.alert.alert-success"
                  ){ should have_content( "Uppgifterna sparade")}}
        it{ should have_link( "Logga ut", :href => log_out_path)}
        specify{ @user.name.should  == @new_name}
        specify{ @user.email.should == @new_email}
      end
    end

    context "admin" do

      before do
        @admin = create_test_user :role => "admin",
                                  :name => "Admin", :email => "ad@min"
        fake_log_in @admin
        @editor = @admin
        @edited = @user
      end

      admin_examples
    end
  end
end

