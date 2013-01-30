require "spec_helper"

describe "User pages" do

  subject{ page}

  describe "index" do

    before do
      @user = create_test_user( :name => "Normal",
                                :email => "normal@exempel.se")
      log_in @user
      visit users_path
    end

    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | Användare")}
    it{ should have_selector( "h1", :text => "Alla användare")}

    describe "pagination" do

      before( :all){ create_test_user :count => 30}
      after( :all){ User.delete_all}

      it{ should have_selector( "div.pagination")}

      it "should list each user" do
        User.paginate( :page => 1).each do |user|
          page.should have_selector( "li", :text => user.name)
        end
      end
    end

    describe "delete links" do

      it{ should_not have_link( "delete")}

      context "as an admin user" do
        before do
          @admin = create_test_user :admin => true, :name => "Admin",
            :email => "anders1lindeberg@gmail.com"
          log_in @admin
          visit users_path
        end

        it{ should have_link( "Ta bort", :href => user_path( User.first))}
        it "should be able to delete another user" do
          expect{ click_link( "Ta bort")}.to change( User, :count).by( -1)
        end
        it{ should_not have_link( "Ta bort", :href => user_path( @admin))}
      end
    end
  end

  describe "Sign_up page" do

    before( :each){ visit sign_up_path}
    let( :submit){ "Registrera ny användare"}

    it{ should have_selector( "h1",    :text => "Ny användare")}
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
        before{ click_button submit}
        let( :user){ User.find_by_email( "user@example.com")}
        it{ should have_selector(
          "title", :text => "Bokning av vittnesstöd | #{ user.name}")}
        it{ should have_selector( "div.alert.alert-success", :text => "Välkommen")}
        it{ should have_link( "Logga ut")}
      end
    end
  end

  describe "profile page" do

    before do
      @user = create_test_user
      # @morning, @afternoon = create_test_booking :count => 2
      visit user_path( @user)
    end

    it{ should have_selector( "h1",    :text => @user.name)}
    it{ should have_selector(
      "title", :text => "Bokning av vittnesstöd | #{ @user.name}")}

=begin
    describe "bookings" do
      it{ should have_content( @morning.court_day)}
      it{ should have_content( @afternoon.court_day)}
      it{ should have_content( @user.bookings.count)}
    end
=end
  end

  describe "edit" do

    before( :each) do
      visit log_in_path
      @user = create_test_user
      log_in @user
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
        "title", :text => "Bokning av vittnesstöd | #{ new_name}")}
        it{ should have_selector( "div.alert.alert-success")}
        it{ should have_link( "Logga ut", :href => log_out_path)}
        specify{ @user.reload.name.should  == new_name}
        specify{ @user.reload.email.should == new_email}
    end
  end
end

