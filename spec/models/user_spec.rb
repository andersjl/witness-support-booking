require 'spec_helper'

describe "User model" do

  before{ @user = create_test_user :do_not_save => true}

  subject{ @user}

  it{ should respond_to( :name)}
  it{ should respond_to( :email)}
  it{ should respond_to( :password_digest)}
  it{ should respond_to( :password)}
  it{ should respond_to( :password_confirmation)}
  it{ should respond_to( :remember_token)}
  it{ should respond_to( :role)}
  it{ should respond_to( :admin?)}
  it{ should respond_to( :enabled?)}
  it{ should respond_to( :authenticate)}
  it{ should respond_to( :bookings)}
  it{ should respond_to( :booked?)}
  it{ should respond_to( :book!)}

  it{ should be_valid}
  it{ should_not be_admin}

  describe "accessible attributes" do
    it "should not allow access to role" do
      lambda{ User.new( :role => "disabled")}.should raise_error(
        ActiveModel::MassAssignmentSecurity::Error)
    end    
  end

  context "with role attribute set to 'admin'" do
    before do
      @user.role = "admin"
      @user.save!
    end
    it{ should be_admin}
  end
 
  context ".order_by_role_and_name" do
    before{
      [ lambda{ create_test_user :name => "a", :role => "disabled",
                                 :email => "11"},
        lambda{ create_test_user :name => "z", :role => "disabled",
                                 :email => "12"},
        lambda{ create_test_user :name => "a", :role => "normal",
                                 :email => "21"},
        lambda{ create_test_user :name => "z", :role => "normal",
                                 :email => "22"},
        lambda{ create_test_user :name => "a", :role => "admin",
                                 :email => "31"},
        lambda{ create_test_user :name => "z", :role => "admin",
                                 :email => "32"}
      ].shuffle.each{ |creation| creation.call}}
    specify{ User.order_by_role_and_name.should ==
               User.find( :all, :order => "email")}
  end

  context "validation" do

    context "when name is not present" do
      before{ @user.name = " "}
      it{ should_not be_valid}
    end

    context "when email is not present" do
      before{ @user.email = " "}
      it{ should_not be_valid}
    end

    context "when email address is taken" do
      before{ @user_with_same_email =
                create_test_user :email => @user.email.upcase}
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

    describe "when role is missing" do
      before{ @user.role = nil}
      it{ should be_invalid}
    end

    describe "with an undefined role" do
      before{ @user.role = "unknown"}
      it{ should be_invalid}
    end
  end

  describe "#enabled?" do

    context "when role is 'disabled'" do
      before{ @user.role = "disabled"}
      it{ should_not be_enabled}
    end

    context "when role is 'normal'" do
      before{ @user.role = "normal"}
      it{ should be_enabled}
    end

    context "when role is 'admin'" do
      before{ @user.role = "admin"}
      it{ should be_enabled}
    end
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
      @court_day = create_test_court_day :morning => 2, :afternoon => 2
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

          specify "second booking fails" do
            lambda{ @user.book! @court_day, session
                  }.should raise_error( ActiveRecord::RecordNotUnique)
          end

          specify "destroyed along with self" do
            expect{ @user.destroy}.to change( Booking, :count).by( -1)
          end
        end
      end
    end
  end
end

