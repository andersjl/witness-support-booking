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
    bookings =
      [ [ 1, 3], [ 1, 6], [ 2, 5], [ 2, 2], [ 3, 1], [ 3, 3]
      ].collect do |u, s|
        Booking.create! user: eval( "u#{ u}"), court_session: eval( "s#{ s}")
      end
    s6.need = 0
    s6.save!  # test that s6 and the booking (u1, s6) are not stored
    bookings
  end

  subject{ page}

  describe "save & load" do

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
        @exported_bookings = create_sample_data.delete_if{
                      |b| b.court_session.need == 0}.map!{ |b| b.inspect}.sort
        @deleted_email = User.where( "role = ?", "normal").sample.email
        @kept_email = User.where( "role = ? and email != ?",
                                  "normal", @deleted_email).sample.email
        xml_data = Database.new.all_data
        File.open( correct_xml, "w"){ |f| f.write( xml_data)}
        File.open( erronous_xml, "w"){ |f| f.write( xml_data + "<extra>")}
        @exported_count = AllDataDefs.model_tags.inject( { }) do |cnt, tag|
          cls = AllDataDefs.model_class( tag)
          cnt[ cls] =
            case cls.name
            when "CourtSession"
              cls.all.count{ |s| s.need > 0}
            when "Booking"
              cls.all.count{ |b| b.court_session.need > 0}
            else
              cls.count
            end
          cnt
        end
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
          let :users do
            result = User.where( "court_id = ?",
                                 Court.find_by_name( "This Court")
                               ).sort{ |u1, u2| u1.name <=> u2.name}
            result.delete_if{ |u| [ email_m1, email_m2].include?( u.email)}
            result
          end
          let( :court_sessions) do
            CourtSession.where( "court_id = ?",  # (date, start) order
                                Court.find_by_name( "This Court"))
          end

          AllDataDefs.model_tags.each do |tag|
            next if AllDataDefs.attr_tags( tag).count == 0
            model = AllDataDefs.model_class( tag)
            context( "#{ model}.count") do
              specify{ model.count.should ==
                         @exported_count[ model] + ((model == User) ? 1 : 0)}
            end
          end

          context "bookings" do
            specify do
              Booking.all.inject( [ ]) do |a, b|
                next a unless b.user.court == court_this
                a << b.inspect
              end.sort.should == @exported_bookings
            end
          end
        end
      end
    end
  end

  describe "destroy old" do

    DIRECT_GETTER = lambda{ |obj| obj.date}
    INDIRECT_GETTER = lambda{ |obj| obj.court_session.date}
    DISTANT_PAST = Date.current - 100000
    DISTANT_FUTURE = Date.current + 100000

    before do
      create_sample_data
      @master = create_test_user( email: "ma@ster", role: "master",
                                  password: "master")
      fake_log_in( @master)
      @rows_p_date =
        [ [ nil, Court, User],
          [ DIRECT_GETTER, CourtDayNote, CourtSession],
          [ INDIRECT_GETTER, Booking, CancelledBooking]
        ].inject( { }) do |rows_p_date, models|
          date_getter = models.shift
          models.each do |model|
            model.all.each do |obj|
              date = date_getter ? date_getter.call( obj) : DISTANT_FUTURE
              rows_p_date[ date] ||= 0
              rows_p_date[ date] += 1
            end
          end
          rows_p_date
        end.to_a.sort.reverse
      visit user_path( @master)
    end

    def count_not_older_than( first_date)
      first_date = first_date.to_date
      @rows_p_date.inject( 0) do |total, date_count|
        date, count = date_count
        break( total) if date < first_date
        total + count
      end
    end

    def total_count; count_not_older_than DISTANT_PAST end
    def first_date; @rows_p_date[ -1][ 0] end
    def last_date; @rows_p_date[ 1][ 0] end

    context "initial data" do

      it{ within( :id, "search-form"){ should have_selector(
            "label", text: "#{ total_count}")}}
      it{ within( :id, "search-form"){ should have_selector(
            "input[value='#{ first_date}']")}}
      it{ within( :id, "drop-older-form"){ should have_content first_date}}
    end

    shared_examples_for "setting any" do

      context "count date" do
        before do
          within :id, "search-form" do
            fill_in "count_date", with: @chosen_date
            click_button "OK"
          end
        end
        it{ within( :id, "search-form"){ should have_selector(
              "label", text: "#{ count_not_older_than @chosen_date}")}}
        it{ within( :id, "search-form"){ should have_selector(
              "input[value='#{ @chosen_date}']")}}
        it{ within( :id, "drop-older-form"){ should have_content first_date}}

        context "dropping older" do
          before do
            @expected_new_first_date = @chosen_date.to_date
            while !@rows_p_date.assoc( @expected_new_first_date)
              @expected_new_first_date += 1
            end
            within( :id, "drop-older-form"){
              click_button t( "database.drop_older.label")}
          end
          it{ within( :id, "search-form"){ should have_selector(
                "label", text: "#{ count_not_older_than @chosen_date}")}}
          it{ within( :id, "search-form"){ should have_selector(
                "input[value='#{ @chosen_date}']")}}
          it do
            within( :id, "drop-older-form"){
              should have_content @expected_new_first_date}
            if @expected_new_first_date != @chosen_date.to_date
              puts "                count date #{ @chosen_date}"
            end
          end
          it do
            within( "div.alert.alert-success"){
                should have_content( @chosen_date)}
            if @expected_new_first_date != @chosen_date.to_date
              puts "                new first date #{
                     @expected_new_first_date}"
            end
          end
        end
      end
    end

    context "oldest" do
      before{ @chosen_date = first_date.iso8601}
      it_behaves_like "setting any"
    end

    context "intermediate" do
      before{ @chosen_date =
                (first_date + 1 + rand( last_date - first_date - 1)).iso8601}
      it_behaves_like "setting any"
    end

    context "last" do
      before{ @chosen_date = last_date.iso8601}
      it_behaves_like "setting any"
    end
  end
end
