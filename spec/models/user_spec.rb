require 'spec_helper'

describe "User model" do

  before{ @user = create_test_user do_not_save: true}

  subject{ @user}

  it{ should respond_to( :court)}
  it{ should respond_to( :name)}
  it{ should respond_to( :email)}
  it{ should respond_to( :password_digest)}
  it{ should respond_to( :password)}
  it{ should respond_to( :password_confirmation)}
  it{ should respond_to( :remember_token)}
  it{ should respond_to( :role)}
  it{ should respond_to( :admin?)}
  it{ should respond_to( :master?)}
  it{ should respond_to( :enabled?)}
  it{ should respond_to( :authenticate)}
  it{ should respond_to( :bookings)}
  it{ should respond_to( :booked?)}

  it{ should be_valid}
  it{ should_not be_admin}
  it{ should_not be_admin( court_this)}
  it{ should_not be_admin( court_other)}
  it{ should_not be_master}

  context "with role attribute set to 'master'" do
    before do
      @user.role = "master"
      @user.save!
    end
    it{ should be_admin}
    it{ should be_admin( @user.court)}
    it{ should be_admin( Court.find_by_name( "Other Court"))}
    it{ should be_master}
  end

  context "with role attribute set to 'admin'" do
    before do
      @user.role = "admin"
      @user.save!
    end
    it{ should be_admin}
    it{ should be_admin( @user.court)}
    it{ should_not be_admin( Court.find_by_name( "Other Court"))}
    it{ should_not be_master}
  end

  describe "#role_to_order" do
    specify{ pending "implicit in .order_by_role_and_name"; fail}
  end

  describe ".order_by_role_and_name" do
    before{
      [ lambda{ create_test_user name: "a", role: "disabled", email: "11"},
        lambda{ create_test_user name: "z", role: "disabled", email: "12"},
        lambda{ create_test_user name: "a", role: "normal",   email: "21"},
        lambda{ create_test_user name: "z", role: "normal",   email: "22"},
        lambda{ create_test_user name: "a", role: "admin",    email: "31"},
        lambda{ create_test_user name: "z", role: "admin",    email: "32"},
        lambda{ create_test_user name: "a", role: "master",   email: "41"},
        lambda{ create_test_user name: "z", role: "master",   email: "42"}
      ].shuffle.each{ |creation| creation.call}}
    specify{ User.order_by_role_and_name( court_this).should ==
               User.where( court_id: court_this).order( :email)}
  end

  describe ".valid_role?" do
    USER_ROLES.each{ |role| specify{ User.valid_role?( role).should be_truthy}}
    specify{ User.valid_role?( "unknown role").should_not be_truthy}
  end

  describe ".disabled_count" do

    before( :all){ @created_users =
         create_test_user( count: 2, role: "disabled") +
         create_test_user( count: 3, court: court_other, role: "disabled")}
    after( :all){ clear_models}

    context( "no arg"){ specify{ User.disabled_count.should == 5}}
    context( "( nil)"){ specify{ User.disabled_count( nil).should == 5}}
    context( "( court)"){ specify{ User.disabled_count( court_this).should == 2}}
  end

  context "validation" do

    context "when court is not present" do
      before{ @user.court = nil}
      it{ should_not be_valid}
    end

    context "when email is not present" do
      before{ @user.email = " "}
      it{ should_not be_valid}
    end

    context "when email address is taken" do
      before do
        @user_with_same_email = create_test_user email: @user.email.upcase
        @user.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @user.errors}
        its( [ :email]){ should include( t( "user.error.email_taken"))}
      end
      context "on another court" do
        before{ @user_with_same_email.
                  update_attribute :court, Court.find_by_name( "Other Court")}
        it{ should be_valid}
      end
    end

    context "when name is not present" do
      before{ @user.name = " "}
      it{ should_not be_valid}
    end

    context "when password is not present" do
      before{ @user.password = @user.password_confirmation = " "}
      it{ should_not be_valid}
    end

    describe "with a password that's too short" do
      before{ @user.password = @user.password_confirmation = "a" * 5}
      it{ should be_invalid}
    end

    context "when password confirmation is nil" do
      before{ @user.password_confirmation = nil}
      it{ should_not be_valid}
    end

    describe "when password doesn't match confirmation" do
      before{ @user.password_confirmation = "mismatch"}
      it{ should_not be_valid}
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

    context "when role is 'master'" do
      before{ @user.role = "master"}
      it{ should be_enabled}
    end
  end

  describe "return value of authenticate method" do

    before do
      @user.save!
      @found_user =
        User.find_by_court_id_and_email( @user.court.id, @user.email)
      # in absence of the next line we get an error later that seems to
      # indicate that @found_user.inspect evaluates court to nil
      @found_user.court
    end

    context "with valid password" do
      it{ should == @found_user.authenticate( @user.password)}
    end

    context "with invalid password" do
      let( :user_for_invalid_password){ @found_user.authenticate( "invalid")}
      it{ should_not == user_for_invalid_password}
      specify{ user_for_invalid_password.should be_falsey}
    end

  end

  describe "#remember token" do
    before{ @user.save!}
    its( :remember_token){ should_not be_blank}
  end

  describe "#booked?" do

    before do
      @user.save!
      @session = create_test_court_session need: 2
    end

    it{ should_not be_booked( @session)}

    context "booked" do

      before{ Booking.create! user: @user, court_session: @session,
                              booked_at: @session.date - rand( 10)
            }

      it{ should be_booked( @session)}

      it "is actually booked" do
        @user.bookings.first.court_session.should == @session
      end

      specify "second booking fails" do
        lambda do
          b = Booking.new user: @user, court_session: @session,
                          booked_at: @session.date - rand( 10)
          b.save!
        end.should raise_error( ActiveRecord::ActiveRecordError, /unique/i)
      end

      specify "destroyed along with self" do
        expect{ @user.destroy}.to change( Booking, :count).by( -1)
      end
    end
  end
end

