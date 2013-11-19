require "spec_helper"
require "database"

describe "Database views" do

  def create_sample_data
    u1, u2, u3 = create_test_user count: 3
    s1, s2, s3, s4, s5, s6 = create_test_court_session count: 6,
                               date: CourtDay.add_weekdays( Date.current, -2)
    6.times do |i|
      s = eval "s#{ i + 1}"
      s.update_attribute :need, i / 2 + 1
      create_test_court_day_note date: s.date if rand( 3) > 0
    end
    @has_1_booking = s6
    @has_2_bookings = s3
    @overbooked_user = u3
    [ [ 1, 3], [ 1, 6], [ 2, 5], [ 2, 2], [ 3, 1], [ 3, 3]].collect do |u, s|
      Booking.create! user: eval( "u#{ u}"), court_session: eval( "s#{ s}")
    end
  end

  subject{ page}

  describe "save & load" do

    let( :email_m1){ "first@master"}

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
      let( :overbooked_xml){ "tmp/test/witness_support_dump_overbooked.xml"}
      let( :email_m2){ "second@master"}

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
        @orig_bookings = create_sample_data.collect{ |b| b.inspect}.sort
        @deleted_email = User.where( "role = ?", "normal").sample.email
        @kept_email = User.where( "role = ? and email != ?",
                                  "normal", @deleted_email).sample.email
        xml_data = Database.new.all_data
        File.open( correct_xml, "w"){ |f| f.write( xml_data)}
        File.open( erronous_xml, "w"){ |f| f.write( xml_data + "<extra>")}
        @orig_count = AllDataDefs.model_tags.inject( { }) do |cnt, tag|
          cls = AllDataDefs.model_class( tag)
          cnt[ cls] = cls.count
          cnt
        end
        @has_1_booking.update_attribute :need, 0
        @has_2_bookings.update_attribute :need, 1
        xml_data = Database.new.all_data
        File.open( overbooked_xml, "w"){ |f| f.write( xml_data)}
        @has_1_booking =
          [ @has_1_booking.court.name, @has_1_booking.start_time.iso8601]
        @has_2_bookings =
          [ @has_2_bookings.court.name, @has_2_bookings.start_time.iso8601]
        @overbooked_user = [ @overbooked_user.court.name, @overbooked_user.email]
        User.all.each{ |u| u.destroy if u.email != @kept_email}
        @curr_count = AllDataDefs.model_tags.inject( { }) do |cnt, tag|
          cls = AllDataDefs.model_class( tag)
          cnt[ cls] = cls.count + (cls == User ? 1 : 0)
          cnt
        end
      end

      after :all do
        AllDataDefs.model_tags.
          each{ |t| AllDataDefs.model_class( t).delete_all}
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
          AllDataDefs.model_tags.each do |tag|
            model = AllDataDefs.model_class( tag)
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

        it{ within( "div.alert.alert-success"){
              should have_content( t( "database.created"))}}

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

          AllDataDefs.model_tags.each do |tag|
            next if AllDataDefs.attr_tags( tag).count == 0
            model = AllDataDefs.model_class( tag)
            context( "#{ model}.count") do
              specify{ model.count.should ==
                                @orig_count[ model] + ((model == User) ? 1 : 0)}
            end
          end

          context "bookings" do
            specify do
              Booking.all.inject( [ ]) do |a, b|
                next a unless b.user.court == court_this
                a << b.inspect
              end.sort.should == @orig_bookings
            end
          end
        end
      end

      context "with overbooked" do

        before do
          attach_file "database_all_data", overbooked_xml
          click_on t( "general.ok")
        end

        it{ within( "div.alert.alert-success"){
              should have_content( t( "database.created"))}}

        AllDataDefs.model_tags.each do |tag|
          next if AllDataDefs.attr_tags( tag).count == 0
          model = AllDataDefs.model_class( tag)
          context( "#{ model}.count") do
            specify do
              model.count.should ==
                @orig_count[ model] + case tag
                                      when "user"          then  1
                                      when "court_session" then -1
                                      when "booking"       then -2
                                      else                       0
                                      end
            end
          end
        end

        context "bookings" do
          specify do
            orig_bookings =
              @orig_bookings.dup.delete_if{ |b|
                @has_1_booking.inject( true){ |r, e| r && b.include?( e)} ||
                ( @has_2_bookings.inject( true){ |r, e| r && b.include?( e)} &&
                  @overbooked_user.inject( true){ |r, e| r && b.include?( e)})}
            Booking.all.inject( [ ]) do |a, b|
              next a unless b.user.court == court_this
              a << b.inspect
            end.sort.should == orig_bookings
          end
        end
      end
    end
  end
end

