require 'spec_helper'

describe "Authentication pages" do

  subject{ page}

  describe "log_in page" do
    before{ visit log_in_path}

    it{ should have_selector( 'h1', :text => 'Logga in')}
    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | Logga in")}
  end

  describe "log_in" do
    
    before{ visit log_in_path}

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
        fill_in "E-post",   :with => @user.email
        fill_in "Lösenord", :with => @user.password
        click_button "Logga in"
      end

      it{ should have_selector(
        "title", :text => "Bokning av vittnesstöd | #{ @user.name}")}
      it{ should have_link( 'Användare', :href => users_path)}
      it{ should have_link( 'Mina uppgifter', :href => user_path( @user))}
      it{ should have_link( "Ändra #{ @user.name}",
                             :href => edit_user_path( @user))}
      it{ should have_link( 'Logga ut', :href => log_out_path)}
      it{ should_not have_link( 'Logga in', :href => log_in_path)}

      describe "followed by log out" do
        before{ click_link "Logga ut"}
        it{ should have_link( 'Logga in')}
      end
    end
  end

=begin
skipped the functionality, too little user value
  context "when attempting to visit a protected page" do

    before do
      @user = create_test_user
      visit edit_user_path( @user)
      fill_in "E-post", :with => @user.email
      fill_in "Lösenord", :with => @user.password
      click_button "Logga in"
    end

    describe "after logging in" do
      it "should render the desired protected page" do
        page.should have_selector( "title",
          :text => "Bokning av vittnesstöd | Ändra #{ @user.name}")
      end
    end
  end

  context "after logging out and back in as other user" do

    before do
      @user1, @user2 = create_test_user :count => 2
      visit log_in_path
      fill_in "E-post", :with => @user1.email
      fill_in "Lösenord", :with => @user1.password
      click_button "Logga in"
      visit users_path
      click_link "Logga ut"
      click_link "Logga in"
      fill_in "E-post", :with => @user2.email
      fill_in "Lösenord", :with => @user2.password
      click_button "Logga in"
    end

    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | #{ @user2.name}")}
  end

  context "after logging in while logged in" do

    before do
      @user = create_test_user
      visit log_in_path
      fill_in "E-post", :with => @user.email
      fill_in "Lösenord", :with => @user.password
      click_button "Logga in"
      visit users_path
      visit root_path
      visit log_in_path
      fill_in "E-post", :with => @user.email
      fill_in "Lösenord", :with => @user.password
      click_button "Logga in"
    end

    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | #{ @user.name}")}
  end
=end
end

