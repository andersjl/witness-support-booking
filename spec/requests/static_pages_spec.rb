# encoding: UTF-8

require "spec_helper"

describe "Static pages" do

  subject{ page}

  describe "Home page" do

    shared_examples_for "any user's start page" do
      it{ should have_selector "title", :text => t( "general.application")}
      it{ should have_link t( "general.application"), :href => root_path}
      it{ should have_link "Hjälp", :href => help_path}
      it{ should have_link "Om webbokningen", :href => about_path}
      it{ should have_selector "h1", :text => t( "general.application")}
    end

    shared_examples_for "any enabled user's start page" do
      it{ should have_link "Rondningar", :href => court_days_path}
      it{ should have_link "Användare", :href => users_path}
    end

    context "unknown user" do
      before{ visit root_path}
      it_behaves_like "any user's start page"
    end

    USER_ROLES.each do |role|
      context "#{ role} user" do
        before do
          fake_log_in( @user = create_test_user( :role => role))
          visit root_path
        end
        it_behaves_like "any user's start page"
        it{ should have_link "Logga ut", :href => log_out_path}
        if User.role_to_order( role) > User.role_to_order( "disabled")
          it_behaves_like "any enabled user's start page"
        end
      end
    end
  end

  describe "Help page" do
    before( :each) { visit help_path}
    it { should have_selector( "h1", :text => "Hjälpsida")}
    it { should have_selector(
           "title", :text => t( "general.application") + " | Hjälp")}
  end

  describe "About page" do
    before( :each) { visit about_path}
    it { should have_selector( "h1", :text => "Om webbokningen")}
    it { should have_selector( "title",
                               :text => t( "general.application") + " | Om")}
  end

end

