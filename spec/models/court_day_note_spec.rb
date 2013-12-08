require 'spec_helper'

describe "CourtDayNote model" do

  before{ @day_note = create_test_court_day_note do_not_save: true}
  subject{ @day_note}

  it{ should respond_to :court}
  it{ should respond_to :date}
  it{ should respond_to :text}

  context "validation" do

    context "when court is missing" do
      before{ @day_note.court = nil}
      it{ should_not be_valid}
    end

    context "when date is missing" do
      before{ @day_note.date = nil}
      it{ should_not be_valid}
    end

    context "when date is taken" do
      before do
        @other_day_note = create_test_court_day_note court: @day_note.court,
                                                     date:  @day_note.date
        @day_note.valid?
      end
      it{ should_not be_valid}
      context "errors" do
        subject{ @day_note.errors}
        its( [ :date]){ should include( t( "court_day_note.error.date_taken"))
                      }
      end
      context "on another court" do
        before{ @other_day_note.update_attribute :court,
                                          Court.create!( name: "Yet Another")}
        it{ should be_valid}
      end
    end

    [ "Saturday", "Sunday"].each do |weekend_day|
      context "when on a #{ weekend_day}" do
        before do
          @date = @day_note.date - (@day_note.date.cwday +
                                      (weekend_day == "Saturday" ? 1 : 0)) + 7
          @day_note.date = @date
          @day_note.valid?
        end
        it{ should_not be_valid}
        context "errors" do
          subject{ @day_note.errors}
          its( [ :date]){ should include( t( "court_day.error.weekend",
                                dow: t( "date.day_names")[ @date.cwday % 7]))}
        end
      end
    end

    context "when text is missing" do
      before do
        @day_note.text = "\t  \n  "
        @day_note.valid?
      end
      it{ should_not be_valid}
    end
  end

  context "earliest first" do
    before do
      create_test_court_day_note date: Date.tomorrow + 2
      @day_note.save!
      create_test_court_day_note date: Date.tomorrow
    end
    specify{ CourtDayNote.where( court_id: @day_note.court
                               ).first.should == @day_note}
  end
end

