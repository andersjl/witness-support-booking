require 'spec_helper'

describe "User model" do

  before{ @user = User.new( :name => "Example User",
                            :email => "user@example.com",
                            :password => "foobaz",
                            :password_confirmation => "foobaz")}

  subject{ @user}

  it{ should respond_to( :name)}
  it{ should respond_to( :email)}
  it{ should respond_to( :password_digest)}
  it{ should respond_to( :password)}
  it{ should respond_to( :password_confirmation)}
  it{ should respond_to( :remember_token)}
  it{ should respond_to( :admin)}
  it{ should respond_to( :authenticate)}
  it{ should respond_to( :bookings)}
# it{ should respond_to( :court_days)}
  it{ should respond_to( :booked?)}
  it{ should respond_to( :book!)}

  it{ should be_valid}
  it{ should_not be_admin}

  describe "accessible attributes" do
    it "should not allow access to admin" do
      lambda{ User.new( :admin => true)}.should raise_error(
        ActiveModel::MassAssignmentSecurity::Error)
    end    
  end

  context "with admin attribute set to 'true'" do
    before do
      @user.save!
      @user.toggle!( :admin)
    end

    it{ should be_admin}
  end

  context "when name is not present" do
    before{ @user.name = " "}
    it{ should_not be_valid}
  end

  context "when email is not present" do
    before{ @user.email = " "}
    it{ should_not be_valid}
  end

  context "when email address is already taken" do
    before do
      ( user_with_same_email = @user.dup).email.upcase!
      user_with_same_email.save!
    end
    it{ should_not be_valid}
  end

  context "when password is not present" do
    before{ @user.password = @user.password_confirmation = " "}
    it{ should_not be_valid}
  end

  context "when password confirmation is nil" do
    before{ @user.password_confirmation = nil}
    it{ should_not be_valid}
  end

  describe "when password doesn't match confirmation" do
    before{ @user.password_confirmation = "mismatch"}
    it{ should_not be_valid}
  end

  describe "with a password that's too short" do
    before{ @user.password = @user.password_confirmation = "a" * 5}
    it{ should be_invalid}
  end
  
  describe "return value of authenticate method" do

    before do
      @user.save!
      @found_user = User.find_by_email( @user.email)
    end

    context "with valid password" do
      it{ should == @found_user.authenticate( @user.password)}
    end

    context "with invalid password" do
      let( :user_for_invalid_password){ @found_user.authenticate( "invalid")}
      it{ should_not == user_for_invalid_password}
      specify{ user_for_invalid_password.should be_false}
    end

  end

  describe "#remember token" do
    before{ @user.save!}
    its( :remember_token){ should_not be_blank}
  end

  describe "#book!" do

    before do
      @user.save!
      @court_day = create_test_court_day :morning => 1, :afternoon => 2
    end

    [ :morning, :afternoon].each do |session|
      context session do

        it{ should_not be_booked( @court_day, session)}

        context "booked" do

          before{ @user.book! @court_day, session}

          it{ should be_booked( @court_day, session)}

          it "is actually booked" do
            @user.bookings.first.court_day.should == @court_day
            @user.bookings.first.session.should == session
          end

          it "second booking fails" do
            lambda{ @user.book! @court_day, session
                  }.should raise_error( ActiveRecord::RecordNotUnique)
          end
        end
      end
    end
  end
end

