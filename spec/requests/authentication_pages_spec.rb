require 'spec_helper'

describe "AuthenticationPages" do

  subject { page}

  describe "signin page" do
    before { visit signin_path}

    it { should have_selector( 'h1', :text => 'Logga in')}
    it { should have_selector(
      "title", :text => "Bokning av vittnesstöd | Logga in")}
  end

  describe "signin" do
    
    before { visit signin_path}

    context "with invalid information" do
      before { click_button "Logga in"}
      it { should have_selector(
        "title", :text => "Bokning av vittnesstöd | Logga in")}
      it { should have_selector( 'div.alert.alert-error', :text => 'Ogiltig')}
      describe "after visiting another page" do
        before { click_link "Start"}
        it { should_not have_selector( 'div.alert.alert-error')}
      end
    end
    
    context "with valid information" do

      before do
        @user = User.create :email                 => "ex.empel@exempel.se",
                            :name                  => "Ex Empel",
                            :password              => "dåligt",
                            :password_confirmation => "dåligt"
        fill_in "E-post",   :with => @user.email
        fill_in "Lösenord", :with => @user.password
        click_button "Logga in"
      end

      it { should have_selector( 'title',          :text => @user.name)}
      it { should have_link(     'Mina uppgifter', :href => user_path( @user))}
      it { should have_link(     'Logga ut',       :href => signout_path)}
      it { should_not have_link( 'Logga in',       :href => signin_path)}

      describe "followed by signout" do
        before { click_link "Logga ut"}
        it { should have_link( 'Logga in')}
      end

    end

  end

end

