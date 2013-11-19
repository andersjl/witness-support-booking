require 'spec_helper'

describe "Database model" do
  before{ @database = Database.new all_data: nil}
  subject{ @database}
  it{ should respond_to( :all_data)}
  it{ should respond_to( :oldest_date)}
  it{ should be_valid}
end

