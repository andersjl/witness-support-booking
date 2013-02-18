require 'spec_helper'

describe "Database model" do

  before do
    @database = Database.new( :all_data => nil, :new_pw => "123456")
  end

  subject{ @database}

  it{ should respond_to( :all_data)}
  it{ should respond_to( :new_pw)}
  it{ should be_valid}

  context "when new_pw is not present" do
    before{ @database.new_pw = nil}
    it{ should_not be_valid}
  end
end

