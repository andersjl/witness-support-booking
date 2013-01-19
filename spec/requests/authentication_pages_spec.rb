require 'spec_helper'

describe "AuthenticationPages" do

  subject{ page}

  describe "signin page" do
    before{ visit signin_path}

    it{ should have_selector( 'h1', :text => 'Logga in')}
    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | Logga in")}
  end

  describe "signin" do
    
    before{ visit signin_path}

    context "with invalid information" do
      before{ click_button "Logga in"}
      it{ should have_selector(
        "title", :text => "Bokning av vittnesstöd | Logga in")}
      it{ should have_selector( 'div.alert.alert-error', :text => 'Ogiltig')}
      describe "after visiting another page" do
        before{ click_link "Start"}
        it{ should_not have_selector( 'div.alert.alert-error')}
      end
    end
    
    context "with valid information" do

      before do
        @user = create_test_user
        sign_in( @user)
      end

      it{ should have_selector(
        "title", :text => "Bokning av vittnesstöd | #{ @user.name}")}
      it{ should have_link( 'Användare', :href => users_path)}
      it{ should have_link( 'Mina uppgifter', :href => user_path( @user))}
      it{ should have_link( "Ändra #{ @user.name}",
                             :href => edit_user_path( @user))}
      it{ should have_link( 'Logga ut', :href => signout_path)}
      it{ should_not have_link( 'Logga in', :href => signin_path)}

      describe "followed by signout" do
        before{ click_link "Logga ut"}
        it{ should have_link( 'Logga in')}
      end
    end
  end

  describe "authorization" do

    describe "for non-signed-in users" do
      
      before{ @user = create_test_user}

      context "when attempting to visit a protected page" do

        before( :each) do
          visit edit_user_path( @user)
          fill_in "E-post", :with => @user.email
          fill_in "Lösenord", :with => @user.password
          click_button "Logga in"
        end

        describe "after signing in" do

          it "should render the desired protected page" do
            page.should have_selector( "title",
              :text => "Bokning av vittnesstöd | Ändra #{ @user.name}")
          end
        end
      end

      describe "in the Users controller" do

        describe "visiting the edit page" do
          before{ visit edit_user_path( @user)}
          it{ should have_selector(
            "title", :text => "Bokning av vittnesstöd | Logga in")}
        end

        describe "submitting to the update action" do
          before{ put user_path( @user)}
          specify{ response.should redirect_to( signin_path)}
        end

        describe "visiting the user index" do
          before{ visit users_path}
          it{ should have_selector( 'title', :text => 'Logga in')}
        end
      end
    end

    describe "as wrong user" do

      before( :each) do
        @user = create_test_user
        @wrong_user = create_test_user( :email => "wrong@example.com")
        sign_in @user
      end

      describe "visiting Users#edit page" do
        before{ visit edit_user_path( @wrong_user)}
        it{ should_not have_selector(
              "title", :text => "Bokning av vittnesstöd | Ändra")}
      end

      describe "submitting a PUT request to the Users#update action" do
        before{ put user_path( @wrong_user)}
        specify{ response.should redirect_to( root_path)}
      end
    end

    describe "as non-admin user" do

      before do
        users = create_test_user( :count => 2)
        @user = users[ 0]
        @non_admin = users[ 1]
        sign_in @non_admin
      end

      describe "submitting a DELETE request to the Users#destroy action" do
        before{ delete user_path( @user)}
        specify{ response.should redirect_to( root_path)}        
      end
    end
  end
end

