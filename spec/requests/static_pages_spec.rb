require 'spec_helper'

describe "StaticPages" do

  subject { page}

  describe "Home page" do
    before( :each) { visit root_path}
    it { should have_selector( "h1", :text => "Bokning av vittnesstöd")}
    it { should have_selector( "title", :text => "Bokning av vittnesstöd")}
    it { should_not have_selector( "title", :text => " | Start")}
  end

  describe "About page" do
    before( :each) { visit about_path}
    it { should have_selector( "h1", :text => "Om webbsidan")}
    it { should have_selector( "title",
                               :text => "Bokning av vittnesstöd | Om")}

  end

  describe "Contact page" do
    before( :each) { visit contact_path}
    it { should have_selector( 'h1', :text => 'Kontaktinformation')}
    it { should have_selector( 'title',
                               :text => "Bokning av vittnesstöd | Kontakt")}
  end

end

