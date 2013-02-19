require 'spec_helper'

describe "StaticPages" do

  subject { page}

  describe "Home page" do
    before( :each) { visit root_path}
    it { should have_selector( "h1", :text => "Bokning av vittnesstöd")}
    it { should have_selector( "title", :text => "Bokning av vittnesstöd")}
    it { should_not have_selector( "title", :text => " | Start")}
    it { should have_link( "Hjälp", :href => help_path)}
    it { should have_link( "Om webbsidan", :href => about_path)}
  end

  describe "Help page" do
    before( :each) { visit help_path}
    it { should have_selector( "h1", :text => "Hjälpsida")}
    it { should have_selector( "title",
                               :text => "Bokning av vittnesstöd | Hjälp")}
  end

  describe "About page" do
    before( :each) { visit about_path}
    it { should have_selector( "h1", :text => "Om webbsidan")}
    it { should have_selector( "title",
                               :text => "Bokning av vittnesstöd | Om")}
  end

end

