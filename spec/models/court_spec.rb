require 'spec_helper'

describe "Court model" do

  before{ @court = Court.new :name => "Test"}
  subject{ @court}

  it{ should respond_to( :name)}
  it{ should respond_to( :link)}
  it{ should respond_to( :users)}
  it{ should respond_to( :court_sessions)}
  it{ should respond_to( :court_day_notes)}
  it{ should be_valid}

  describe "validation" do

    context "when name is missing" do
      before{ @court.name = nil}
      it{ should_not be_valid}
    end

    context "when name is taken" do
      before{ Court.create! :name => @court.name}
      it{ should_not be_valid}
    end
  end

  context "Alphabetical order" do
    before do
      Court.delete_all
      @last = Court.create! :name => "Z"
      @court.save!
      @last = Court.create! :name => "y"
    end
    it{ Court.first.should == @court}
  end

  context "when user defined" do
    before do
      @court.save!
      create_test_user :court => @court
    end
    its( "users.count"){ should == 1}
    specify "inhibits destruction of self" do
      expect{ @court.destroy}.
        to raise_error( ActiveRecord::DeleteRestrictionError)
    end
  end

  [ :court_session, :court_day_note].each do |type|
    context "when #{ type.to_s.camelize} instance defined" do
      before do
        @court.save!
        send "create_test_#{ type}", court: @court
      end
      its( "#{ type}s.count"){ should == 1}
      specify "destroyed along with self" do
        expect{ @court.destroy}.to change( type.to_s.camelize.constantize,
                                           :count).by( -1)
      end
    end
  end
end

