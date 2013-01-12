require 'spec_helper'

describe "StaticPages" do

  describe "Home page" do

    it "has the content 'Bokning av vittnesstöd'" do
      visit "/static_pages/home"
      page.should have_selector( "h1", :text => "Bokning av vittnesstöd")
    end

    it "has the title 'Hem'" do
      visit "/static_pages/home"
      page.should have_selector(
        "title", :text => "Bokning av vittnesstöd | Hem")
    end

  end

  describe "About page" do

    it "has the content 'Om webbsidan'" do
      visit "/static_pages/about"
      page.should have_selector( "h1", :text => "Om webbsidan")
    end

    it "has the title 'Om'" do
      visit '/static_pages/about'
      page.should have_selector(
        "title", :text => "Bokning av vittnesstöd | Om")
    end

  end

end

