require "spec_helper"

describe "Database load form" do

  subject{ page}

  let( :email1){ "first@admin"}

  context "before loading" do

    before do
      fake_log_in( create_test_user( :email => email1, :role => "master",
                                     :password => email1))
      visit new_database_path
    end

    it{ should have_selector( "h1", :text => "VARNING!")}
    it{ should have_content( "RADERA HELA DATABASEN")}
    it{ should have_selector(
      "title", :text => "#{ APPLICATION_NAME} | Läs in fil")}
  end

  context "when file is loaded" do

    let( :correct_xml){ "tmp/test/witness_support_dump.xml"}
    let( :erronous_xml){ "tmp/test/witness_support_dump_munged.xml"}
    let( :email2){ "second@admin"}

    before :all do
      create_test_court :name => "Other"
      create_test_user :email => email1, :role => "master",
                       :password => email1
      create_test_bookings
      xml_data = Database.new.all_data
      File.open( correct_xml, "w"){ |f| f.write( xml_data)}
      File.open( erronous_xml, "w"){ |f| f.write( xml_data + "<extra>")}
      @orig_count = [ Court, User, CourtDay, Booking].inject( { }) do |a, mdl|
        a[ mdl] = mdl.count
        a
      end
      Booking.delete_all
      CourtDay.delete_all
      User.delete_all
      Court.delete_all
    end

    before do
      fake_log_in( create_test_user( :email => email2, :role => "master",
                                     :password => email2))
      @curr_count = [ Court, User, CourtDay, Booking].inject( { }) do |a, mdl|
        a[ mdl] = mdl.count
        a
      end
      visit new_database_path
    end

    it{ should have_selector(
      "title", :text => "#{ APPLICATION_NAME} | Läs in fil")}

    context "with error in data" do
      before do
        attach_file "database_all_data", erronous_xml
        click_on "OK"
      end

      it{ should have_content( "Inläsningen misslyckades")}
      context "database is intact" do
        [ Court, User, CourtDay, Booking].each do |model|
          context( "#{ model}.count"
                 ){ specify{ model.count.should == @curr_count[ model]}}
        end
      end
    end

    context "with good data" do

      before do
        attach_file "database_all_data", correct_xml
        click_on "OK"
      end

      it{ should have_content( "Ny databas inläst")}

      context "user that was master when restoring" do

        before do
          @second_master = User.find_by_email( email2)
          @second_master.password = email2
          fake_log_in @second_master
        end

        it{ @second_master.should be_master}
        it "can log in with old password" do
          should have_selector( "title",
                   :text => "#{ APPLICATION_NAME} | Rondningar")
        end
      end

      context "user that was master when saving but not when restoring" do

        before do
          @first_master = User.find_by_email( email1)
          @first_master.password = email1
          fake_log_in @first_master
        end

        specify{ @first_master.should_not be_enabled}

        it "can log in with restored password" do
          should have_content(
          "Du kommer att få ett mejl till #{ email1} när du kan börja boka!")
        end
      end

      context "restored database" do
        let :users do
          result = User.where( "court_id = ?",
                               Court.find_by_name( "This Court")
                             ).sort{ |u1, u2| u1.name <=> u2.name}
          result.delete_if{ |u| [ email1, email2].include?( u.email)}
          result
        end
        let( :court_days) do
          result = CourtDay.where( "court_id = ?",  # date order
                                   Court.find_by_name( "This Court"))
          result.each{ |cd| cd.court}  # (sic!) some lazy eval problem???
          result
        end

        [ Court, User, CourtDay, Booking].each do |model|
          context( "#{ model}.count") do
            specify{ model.count.should ==
                              @orig_count[ model] + ((model == User) ? 1 : 0)}
          end
        end

        booking_schema.each do |user_ix, court_day_ix, session|
          it{ users[ user_ix - 1].
                should be_booked( court_days[ court_day_ix - 1], session)}
        end
      end
    end
  end
end

