require 'spec_helper'

describe User do

  before { @user = User.new( :name => "Example User",
                             :email => "user@example.com",
                             :password => "foobaz",
                             :password_confirmation => "foobaz")}

  subject { @user}

  it { should respond_to( :name)}
  it { should respond_to( :email)}
  it { should respond_to( :password_digest)}
  it { should respond_to( :password)}
  it { should respond_to( :password_confirmation)}
  it { should respond_to( :remember_token)}
  it { should respond_to( :admin)}
  it { should respond_to( :authenticate)}
  it { should be_valid}
  it { should_not be_admin}

  context "with admin attribute set to 'true'" do
    before do
      @user.save!
      @user.toggle!( :admin)
    end

    it { should be_admin }
  end

  context "when name is not present" do
    before{ @user.name = " "}
    it { should_not be_valid}
  end

  context "when email is not present" do
    before{ @user.email = " "}
    it { should_not be_valid}
  end

  context "when email address is already taken" do
    before do
      ( user_with_same_email = @user.dup).email.upcase!
      user_with_same_email.save
    end
    it { should_not be_valid}
  end

  context "when password is not present" do
    before{ @user.password = @user.password_confirmation = " "}
    it { should_not be_valid}
  end

  context "when password confirmation is nil" do
    before { @user.password_confirmation = nil}
    it { should_not be_valid}
  end

  describe "when password doesn't match confirmation" do
    before { @user.password_confirmation = "mismatch"}
    it { should_not be_valid}
  end

  describe "with a password that's too short" do
    before { @user.password = @user.password_confirmation = "a" * 5}
    it { should be_invalid}
  end
  
  describe "return value of authenticate method" do

    before { @user.save}
    let( :found_user) { User.find_by_email( @user.email)}

    context "with valid password" do
      it { should == found_user.authenticate( @user.password)}
    end

    context "with invalid password" do
      let( :user_for_invalid_password) { found_user.authenticate( "invalid")}
      it { should_not == user_for_invalid_password}
      specify { user_for_invalid_password.should be_false}
    end

  end

  describe "remember token" do
    before { @user.save}
    its( :remember_token) { should_not be_blank}
  end

end

