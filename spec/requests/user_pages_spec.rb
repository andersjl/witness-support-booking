require 'spec_helper'

describe "UserPages" do

  subject { page }

  describe "Signup page" do
    before( :each) { visit signup_path }
    it { should have_selector( 'h1',    :text => 'Ny användare') }
    it { should have_selector(
      "title", :text => "Bokning av vittnesstöd | Ny användare")}
  end

end

