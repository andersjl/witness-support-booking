require 'spec_helper'

=begin
describe Booking do
 
  shared_examples_for "any booking" do

    subject{ @booking}

    it{ should respond_to( :court_day)}
    it{ should respond_to( :afternoon)}
    it{ should respond_to( :user_id)}
    it{ should be_valid}

    context "when saved" do
      before{ @booking.save!}
      it{ should be_valid}
    end
  
    context "when court_day is not present" do
      before{ @booking.court_day = nil}
      it{ should_not be_valid}
    end
  
    context "when afternoon is not present" do
      before{ @booking.afternoon = nil}
      it{ should_not be_valid}
    end
  end
 
  shared_examples_for "any assigned booking" do

    subject{ @booking}

    its( :user){ should == @user}

    context "when duplicate" do
      before{ @booking.dup.save!}
      it{ lambda{ @booking.save!}.should raise_error}
    end
  end

  before do
    @user = create_test_user
    @booking = create_test_booking
  end

  it_behaves_like "any booking"

  it{ lambda{ Booking.new( :user_id => @user.id)
            }.should raise_error( ActiveModel::MassAssignmentSecurity::Error)}

  context "and afternoon" do
    before do
      @morning = @booking
      @booking = Booking.new :court_day => Date.today, :afternoon => true
    end
    it_behaves_like "any booking"
    @booking = @morning
    it_behaves_like "any booking"
  end

  context "assigned" do

    before{ @booking.user_id = @user.id}
    it_behaves_like "any booking"
    it_behaves_like "any assigned booking"

    context "and afternoon" do
      before do
        @morning = @booking
        @booking = Booking.new :court_day => Date.today, :afternoon => true
        @booking.user_id = @user.id
      end
      it_behaves_like "any booking"
      it_behaves_like "any assigned booking"
    end
  end
end
=end

