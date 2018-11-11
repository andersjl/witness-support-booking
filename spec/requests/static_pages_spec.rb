require "spec_helper"

describe "Static pages", :type => :request do

  subject{ page}

  describe "Home page" do

    shared_examples_for "any user's start page" do
      it{ should have_title( t( "general.application"))}
      it{ should have_link t( "general.application"), :href => root_path}
      it{ should have_link t( "general.help.short"), :href => help_path}
      it{ should have_link t( "general.about.long"), :href => about_path}
      it{ should have_selector "h1", :text => t( "general.application")}
    end

    shared_examples_for "any enabled user's start page" do
      it{ should have_link t( "court_days.index.title.weeks"),
                           :href => court_days_path}
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
        it{ should have_link t( "general.log_out"), :href => log_out_path}
        if USER_ROLES.index( "disabled") == USER_ROLES.index( role)
          it do
            should_not have_link t( "users.index.title")
            should_not have_link @user.name
          end
        else
          it_behaves_like "any enabled user's start page"
          if USER_ROLES.index( "normal") == USER_ROLES.index( role)
            it{ should have_link( @user.name, href: user_path( @user))}
          else
            it{ should have_link t( "users.index.title"), :href => users_path}
          end
        end
      end
    end
  end

  describe "Help page" do
    before( :each) { visit help_path}
    it { should have_selector( "h1", text: t( "general.help.long"))}
    it { should have_title(
           "#{ t( 'general.application')} | #{ t( 'general.help.short')}")}
  end

  describe "About page" do
    before( :each) { visit about_path}
    it { should have_selector( "h1", text: t( "general.about.long"))}
    it { should have_title(
           "#{ t( "general.application")} | #{ t( 'general.about.short')}")}
  end

end

