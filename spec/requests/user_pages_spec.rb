require 'spec_helper'

describe "UserPages" do

  subject { page}

  describe "Signup page" do

    before( :each) { visit signup_path}
    let( :submit) { "Registrera ny användare"}

    it { should have_selector( 'h1',    :text => 'Ny användare')}
    it { should have_selector(
      "title", :text => "Bokning av vittnesstöd | Ny användare")}

    context "with invalid information" do
      it "should not create a user" do
        expect { click_button submit}.not_to change( User, :count)
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
        expect { click_button submit}.to change( User, :count).by( 1)
      end

      context "after saving the user" do
        before { click_button submit}
        let( :user) { User.find_by_email( 'user@example.com')}
        it { should have_selector(
          "title", :text => "Bokning av vittnesstöd | #{ user.name}")}
        it { should have_selector( 'div.alert.alert-success', :text => 'Välkommen')}
        it { should have_link( 'Logga ut') }
      end
    end
  end

  describe "Profile page" do
    before( :each) do
      @user = User.create :email                 => "ex.empel@exempel.se",
                          :name                  => "Ex Empel",
                          :password              => "dåligt",
                          :password_confirmation => "dåligt"
      visit user_path( @user)
    end
    it { should have_selector( 'h1',    :text => @user.name)}
    it { should have_selector( 'title', :text => @user.name)}
  end

end

