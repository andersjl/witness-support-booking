require 'spec_helper'

describe "Static pages" do

  subject { page}

  describe "Home page" do
    before( :each) { visit root_path}
    it { should have_selector( "title", :text => APPLICATION_NAME)}
    it { should_not have_selector( "title", :text => "Start")}
    it { should have_link( APPLICATION_NAME, :href => root_path)}
    it { should have_link( "Hjälp", :href => help_path)}
    it { should have_link( "Om webbsidan", :href => about_path)}
    it { should have_selector( "h1", :text => APPLICATION_NAME)}
  end

  describe "Help page" do
    before( :each) { visit help_path}
    it { should have_selector( "h1", :text => "Hjälpsida")}
    it { should have_selector( "title",
                               :text => "#{ APPLICATION_NAME} | Hjälp")}
  end

  describe "About page" do
    before( :each) { visit about_path}
    it { should have_selector( "h1", :text => "Om webbsidan")}
    it { should have_selector( "title",
                               :text => "#{ APPLICATION_NAME} | Om")}
  end

end

