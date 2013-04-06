require "spec_helper"

describe "Database load form" do

  subject{ page}

  let( :email_m1){ "first@admin"}

  context "before loading" do

    before do
      fake_log_in( create_test_user( :email => email_m1, :role => "master",
                                     :password => email_m1))
      visit new_database_path
    end

    it{ should have_selector( "h1", :text => t( "general.warning.caps"))}
    it{ should have_content( t( "databases.new.erase.caps"))}
    it{ should have_selector( "title",
      text: "#{ t( 'general.application')} | #{ t( 'databases.new.title')}")}
  end

  context "when file is loaded" do

    let( :correct_xml){ "tmp/test/witness_support_dump.xml"}
    let( :erronous_xml){ "tmp/test/witness_support_dump_munged.xml"}
    let( :email_m2){ "second@admin"}

    shared_examples_for "logged in" do  # @logged_in
      it "shows correct page after login" do
        if @logged_in.enabled?
          should have_selector( "title",
                                text: "#{ t( 'general.application')
                                        } | #{ t( 'court_days.index.title')}")
        else
          should have_content( t( "static_pages.home.disabled",
                                  email: @logged_in.email))
        end
      end
    end

    before :all do
      create_test_user :court => court_this, :email => email_m1,
                       :role => "master", :password => email_m1
      create_test_bookings
      @deleted_email = User.where( "role = ?", "normal").sample.email
      @kept_email = User.where( "role = ? and email != ?",
                                "normal", @deleted_email).sample.email
      xml_data = Database.new.all_data
      File.open( correct_xml, "w"){ |f| f.write( xml_data)}
      File.open( erronous_xml, "w"){ |f| f.write( xml_data + "<extra>")}
      @orig_count = [ Court, User, CourtDay, Booking].inject( { }) do |a, mdl|
        a[ mdl] = mdl.count
        a
      end
      User.all.each{ |u| u.destroy if u.email != @kept_email}
      @curr_count = [ Court, User, CourtDay, Booking].inject( { }) do |a, mdl|
        a[ mdl] = mdl.count + (mdl == User ? 1 : 0)
        a
      end
    end

    after :all do
      [ Booking, CourtDay, User, Court].each{ |model| model.destroy_all}
    end

    before do
      fake_log_in( create_test_user( :email => email_m2, :role => "master",
                                     :password => email_m2))
      visit new_database_path
    end

    it{ should have_selector( "title",
      text: "#{ t( 'general.application')} | #{ t( 'databases.new.title')}")}

    context "with error in data" do
      before do
        attach_file "database_all_data", erronous_xml
        click_on t( "general.ok")
      end

      it{ should have_content( t( "database.error.parse"))}

      context "master before trying" do

        before do
          @logged_in = User.find_by_email( email_m2)
          fake_log_in @logged_in, email_m2
        end

        it{ @logged_in.should be_master}
        it_behaves_like "logged in"
      end

      it "exists before trying and is also in file keeps role"
      context "normal before trying" do

        before do
          @logged_in = User.find_by_email( @kept_email)
          fake_log_in @logged_in, "bad_pw"
        end

        it{ @logged_in.should be_enabled}
        it{ @logged_in.should_not be_admin}
        it_behaves_like "logged in"
      end

      context "deleted before trying" do
        context( "normal"){
          specify{ User.find_by_email( @deleted_email).should be_nil}}
        context( "master"){
          specify{ User.find_by_email( email_m1).should be_nil}}
      end

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
        click_on t( "general.ok")
      end

      it{ should have_content( t( "database.created"))}

      context "master when restoring" do

        before do
          @logged_in = User.find_by_email( email_m2)
          fake_log_in @logged_in, email_m2
        end

        it{ @logged_in.should be_master}
        it_behaves_like "logged in"
      end

      context "normal before restoring" do

        before do
          @logged_in = User.find_by_email( @kept_email)
          fake_log_in @logged_in, "bad_pw"
        end

        it{ @logged_in.should be_enabled}
        it{ @logged_in.should_not be_admin}
        it_behaves_like "logged in"
      end

      context "deleted before restoring" do

        context "normal" do

          before do
            @logged_in = User.find_by_email( @deleted_email)
            fake_log_in @logged_in, "bad_pw"
          end

          it{ @logged_in.should_not be_enabled}
          it_behaves_like "logged in"
        end

        context "master" do

          before do
            @logged_in = User.find_by_email( email_m1)
            fake_log_in @logged_in, email_m1
          end

          it{ @logged_in.should_not be_enabled}
          it_behaves_like "logged in"
        end
      end

      context "restored database" do
        let :users do
          result = User.where( "court_id = ?",
                               Court.find_by_name( "This Court")
                             ).sort{ |u1, u2| u1.name <=> u2.name}
          result.delete_if{ |u| [ email_m1, email_m2].include?( u.email)}
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

