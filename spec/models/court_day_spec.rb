require 'spec_helper'

describe "CourtDay" do

  describe ".page" do

    require "generators/data"
    include Generators::Data

    before :all do
      users = [ court_this, court_other].inject( { }) do |us, court|
                us[ court] = create_test_user court: court, count: 3
                us
              end
      days = 5 * WEEKS_P_PAGE + 4
      generate_court_days( CourtDay.monday( Date.current) - 4,
                           5 * WEEKS_P_PAGE + 4, court_this )
      generate_bookings( court_this)
      @first_date = CourtDay.monday( Date.current)
      @page = CourtDay.page( court_this, Date.current)
    end

    subject{ @page}

    its( :count){ should == 5 * WEEKS_P_PAGE}
    its( "first.date"){ should == CourtDay.monday( Date.current)}

    specify "it includes releveant sessions" do
      CourtSession.where( "date >= ? and date < ? and court_id = ?",
        @first_date, CourtDay.add_weekdays( @first_date, 5 * WEEKS_P_PAGE),
                          court_this
                        ).each do |session|
        subject.find{ |cd| cd.date == session.date &&
                             cd.sessions.include?( session)}.should be_truthy
      end
    end

    specify "it includes no irrelevant sessions" do
      subject.each do |cd|
        cd.sessions.each do |session|
          if session.reason_to_exist?
            session.should_not be_new_record
          else
            session.should be_new_record
          end
        end
      end
    end

    specify "it includes releveant notes" do
      CourtDayNote.where( "date >= ? and date < ? and court_id = ?",
        @first_date, CourtDay.add_weekdays( @first_date, 5 * WEEKS_P_PAGE),
                          court_this
                        ).each do |note|
        subject.find{ |cd| cd.date == note.date && cd.note == note
                    }.should be_truthy
      end
    end

    specify "it includes no irrelevant notes" do
      subject.each do |cd|
        if cd.note.text.blank?
          cd.note.should be_new_record
        else
          cd.note.should_not be_new_record
        end
      end
    end

    after( :all){ clear_models}

  end

  specify( ".monday"){ pending "not tested"; fail}
  specify( ".add_weekdays"){ pending "not tested"; fail}
  specify( ".ensure_weekday"){ pending "not tested"; fail}
end

