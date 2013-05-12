require "spec_helper"
require "app/helpers/application_helper"
include ApplicationHelper
include UserSessionsHelper

describe "court_days/index" do

  def test_dates( date_in_week)
    (7 * (WEEKS_P_PAGE + 2) + 1).times do |n|
      date = CourtDay.monday( date_in_week) + n - 7
      show = n % 7 < 5 && 6 < n && n < 7 * (WEEKS_P_PAGE + 1)
      yield date, show
    end
  end

  def date_session_to_id( date, session)
    "session-#{ ( date.to_time_in_current_zone +
                    (session == :morning ? MORNING_TIME_OF_DAY :
                                           AFTERNOON_TIME_OF_DAY)).iso8601}"
  end

  def session_to_label( session, long = false)
    t( "court_session.name#{ session == :morning ? MORNING_TIME_OF_DAY :
                                                   AFTERNOON_TIME_OF_DAY
                           }.#{ long ? 'long' : 'short'}")
  end

  def visit_date( date)
    within :id, "weekpicker-bottom" do
      fill_in "datepicker-bottom", with: date
      click_on t( "general.ok")
    end
  end

  def create_tested_date
    # @tested_date -> @tested_id, @tested_cd
    @tested_cd = create_test_court_day date: @tested_date
    @tested_id = date_session_to_id @tested_cd.date, :morning
  end

  def create_and_visit_tested_date
    create_tested_date
    visit_date @tested_date
  end

  def shows( date)
    should have_selector "div[id='court-day-#{ date.iso8601}']"
  end

  subject{ page}

  before do
    @monday = CourtDay.monday( Date.current)
    test_mon = CourtDay.monday( Date.current + 2)
    @first_date = test_mon <= Date.current ? Date.current + 1 : test_mon
    @n_changeable = 6 - @first_date.cwday
    # Today                 | @cd.date possible range
    # Sunday   .. Wednesday | Tomorrow    .. Friday
    # Thursday .. Saturday  | Next Monday .. next Friday
    @cd = create_test_court_day date: @first_date + rand( @n_changeable),
      sessions: [ [ MORNING_TIME_OF_DAY, 1], [ AFTERNOON_TIME_OF_DAY, 3]],
      note: "tested note"
    @cd_id = "court-day-#{ @cd.date.iso8601}"
    @am_id = date_session_to_id @cd.date, :morning
    @pm_id = date_session_to_id @cd.date, :afternoon
    @note_id = "note-#{ @cd.date.iso8601}"
    @booked_user = create_test_user name: "Berit Bokad",
                                    email: "bokad@example.com"
    Booking.create! user: @booked_user, court_session: @cd.sessions[ 1]
  end

  shared_examples_for "on court_days index page" do
    it{ should have_selector( "title",
    text: "#{ t( 'general.application')} | #{ t( 'court_days.index.title')}")}
    it{ should have_selector( "h1", text: t( "court_days.index.title"))}
  end

 shared_examples_for "any week" do
    # @tested_date, @user

    it "has correct days" do
      test_dates( @tested_date) do |date, show|
        if show
          should have_content date.iso8601
        else
          should_not have_content date.iso8601
        end
      end
    end


    it "has controls from now on" do
      test_dates( @tested_date) do |date, show|
        next unless show
        START_TIMES_OF_DAY_DEFAULT.each do |start_tod|
          start = date.to_time_in_current_zone + start_tod
          next unless start > Time.current
          session = page.first :id, "session-#{ start.iso8601}"
          next unless session
          within session do
            if @user.admin?
              should have_selector "select"
            else
              should have_selector "input",
                value: t( "booking.book.label", session: t(
                                     "court_session.name#{ start_tod}.short"))
            end
          end
        end
        if @user.admin? && date >= Date.current
          within( :id, "note-#{ date.iso8601}"){
            should have_selector "textarea"}
        end
      end
    end


    it "has no controls in the past" do
      test_dates( @tested_date) do |date, show|
        next unless show
        START_TIMES_OF_DAY_DEFAULT.each do |start_tod|
          start = date.to_time_in_current_zone + start_tod
          next unless start < Time.current - 1
          session = page.first :id, "session-#{ start.iso8601}"
          next unless session
          session.should_not have_selector "select"
          session.should_not have_selector "input"
        end
        next unless date < Date.current
        note = page.first :id, "note-#{ date.iso8601}"
        next unless note
        note.should_not have_selector "textarea"
      end
    end
  end

  shared_examples_for "any user" do
    # @user

    context "this week" do
      before{ @tested_date = @monday}
      it_behaves_like "any week"
    end

    context "contents" do
      before{ visit_date @first_date}
      it{ within( :id, @cd_id){ should have_content @cd.date}}
      it{ within( :id, @pm_id){ should have_content @booked_user.name}}
      it{ within( :id, @note_id){ should have_content @cd.note.text}}  # no \n!
      it{ within( :id, @cd_id){ should_not have_selector(
          "input[value='#{ t( 'booking.unbook.label')}']")}}
      it{ within( :id, @cd_id){ should_not have_selector(
          "input[value='#{ t( 'booking.book.label')}']")}}
    end

    context "going one week back" do
      before do
        click_button VALUE_LAST_WEEK
        @tested_date = @monday - 7
      end
      it_behaves_like "any week"
    end

    context "going one week forward" do
      before do
        click_button VALUE_NEXT_WEEK
        @tested_date = @monday + 7
      end
      it_behaves_like "any week"
    end

    context "setting the date" do
      before do
        @new_start_date = @monday + 4711 + rand( 7)
        within :id, "weekpicker-bottom" do
          fill_in "start_date", with: @new_start_date
          click_button t( "general.ok")
        end
        @tested_date = CourtDay.monday @new_start_date
      end

      it_behaves_like "any week"

      context "switching user resets the date" do
        before do
          @other = create_test_user( name: "En Annan",
                                     email: "en.annan@example.com")
          fake_log_in @other
          @user = @other
          @tested_date = @monday
        end
        it_behaves_like "any week"
      end
    end
  end

  shared_examples_for "any changed day" do
    # @morning, @afternoon, @note, @first_line,
    # @changed_date, @changed_obj,

    it "model object has correct data" do
      @changed_obj.sessions[ 0].need.should == @morning.to_i
      @changed_obj.sessions[ 1].need.should == @afternoon.to_i
      @changed_obj.note.text.should == @note.strip
    end

    it "page has correct data" do
      within( :id, "court-day-#{ @changed_date}") do
        should have_content( @changed_date)
        @changed_obj.sessions.each_with_index do |session, ix|
          left_to_book = instance_variable_get(
                           "@#{ ix == 0 ? "morning" : "afternoon"}").to_i -
                           session.bookings.count
          within( :id, "session-#{ session.start_time.iso8601}"){
            should have_content( t( "court_session.need.left.long",
                                     count: left_to_book))}
        end
        should have_content( @first_line)
      end
    end
  end

  shared_examples_for "disabled link" do
    # @user

    context "disabled users" do

      before do
        @dis1, @dis2, @dis3 = create_test_user count: 3,
                                               role: "disabled"
        visit court_days_path
      end

      context "on this court" do
        specify do
          if @user.admin?
            within( "div.row.heading"){
                should have_link( t( "court_days.index.users_to_enable",
                                     count: 3), href: users_path)}
          else
            within( "div.row.heading"){ should_not have_content(
                t( "court_days.index.users_to_enable_common"))}
          end
        end
      end

      context "on other court" do
        before do
          @oth1, @oth2, @oth3 =
            create_test_user court: Court.find_by_name( "Other Court"),
                             count: 3, role: "disabled"
          visit court_days_path
        end
        specify do
          if @user.admin?
            within( "div.row.heading"){
                should have_link( t( "court_days.index.users_to_enable",
                                     count: @user.master? ? 6 : 3),
                                  href: users_path)}
          else
            within( "div.row.heading"){ should_not have_content(
                t( "court_days.index.users_to_enable_common"))}
          end
        end
        context "only" do
          before do
            [ @dis1, @dis2, @dis3].each{ |u| u.destroy}
            visit court_days_path
          end
          specify do
            if @user.master?
              within( "div.row.heading"){
                  should have_link( t( "court_days.index.users_to_enable",
                                       count: 3), href: users_path)}
            else
              within( "div.row.heading"){ should_not have_content(
                  t( "court_days.index.users_to_enable_common"))}
            end
          end
        end
      end
    end
  end

  shared_examples_for "any court admin" do
    # @user = @admin, @booked_user, @monday, @cd, @cd_id

    it_behaves_like "on court_days index page"
    it_behaves_like "any user"

    it "has input controls for each changeable Court Day" do
      (5 * WEEKS_P_PAGE).times do |n|
        weeks, days = n.divmod( 5)
        date = @monday + 7 * weeks + days
        if date >= Date.current
          within( :id, "court-day-#{ date}") do
            if Time.current - Date.current.to_time_in_current_zone >
                 AFTERNOON_TIME_OF_DAY
              should have_selector( "select")
            end
            should have_selector( "textarea")
            should have_selector( "input[value='#{ t( 'general.ok')}']")
            CourtSession.find_all_by_date_and_court_id( date, court_this
                                                      ).each do |session|
              session.bookings.each{ |booking| should have_link(
                  booking.user.name, href: booking_path( booking))}
            end
          end
        end
      end
    end

    context "changing and saving" do

      def change( date, morning, afternoon, note)
        # >> @changed_obj, @changed_date
        within :id, "court-day-#{ date.iso8601}" do
          within :id, date_session_to_id( date, :morning) do
            select( morning, from: "court_session_need")
            click_button t( 'general.ok')
          end
          within :id, date_session_to_id( date, :afternoon) do
            select( afternoon, from: "court_session_need")
            click_button t( 'general.ok')
          end
          within :id, "note-#{ date}" do
            fill_in( "court_day_note_text", with: note)
            click_button t( 'general.ok')
          end
        end
        @changed_date = date
        @changed_obj = CourtDay.find_on_present_page( date)
      end

      before do
        @morning = "1"
        @afternoon = "2"
        @first_line = "<- blanks new line->"
        @note = "  #{ @first_line}\nnext line"
        begin
          @new_date = @first_date + rand( @n_changeable)
        end while @new_date == @cd.date
        visit_date @first_date
      end

      context "same week, change and save" do
        before{ change @cd.date, @morning, @afternoon, @note}
        it_behaves_like "any changed day"
      end

      context "same week, new and save" do
        before{ change @new_date, @morning, @afternoon, @note}
        it_behaves_like "any changed day"
      end

      context "next week, new and save" do
        before do
          click_button VALUE_NEXT_WEEK
          change @new_date + 7, @morning, @afternoon, @note
        end
        it_behaves_like "any changed day"
      end

      context "future date, new and save" do
        before do
          weeks, days = (10+ rand( 100)).divmod 5
          new_start_date = @monday + 7 * weeks + days
          visit_date new_start_date
          change( CourtDay.monday( new_start_date) + rand( 5),
                  @morning, @afternoon, @note)
        end
        it_behaves_like "any changed day"
      end

      context "changing need below already booked" do
        it "should warn the booked by email"
      end
    end

    context "unbooking" do

      before do
        Booking.create! user: @booked_user, court_session: @cd.sessions[ 0]
        @morning_id = date_session_to_id @cd.date, :morning
        @afternoon_id = date_session_to_id @cd.date, :afternoon
        visit court_days_path
        visit_date @first_date
      end

      it{ within( :id, @morning_id){ expect{ click_link( @booked_user.name)
                                       }.to change( Booking, :count).by( -1)}}

      context "morning," do
        before{ within( :id, @morning_id){ click_link( @booked_user.name)}}
        context "morning" do
          it{ within( :id,  @morning_id
                    ){ should_not have_content( @booked_user.name)}}
        end
        context "afternoon still" do
          it{ within( :id, @afternoon_id
                    ){ should have_content( @booked_user.name)}}
        end
      end

      context "future" do

        before do
          @tested_date = CourtDay.add_weekdays( @cd.date, 1 + rand( 10))
          create_tested_date
          Booking.create! user: @booked_user,
                          court_session: @tested_cd.sessions[ 0]
          visit_date @tested_date
          within( :id, @tested_id){ click_link( @booked_user.name)}
        end

        it{ shows @tested_date}
        specify{ @booked_user.should_not be_booked( @tested_cd.sessions[ 0 ])}
      end

      context "past" do

        before do
          @tested_date = CourtDay.add_weekdays( Date.current, -1 - rand( 10))
          create_tested_date
          Booking.create! user: @booked_user,
                          court_session: @tested_cd.sessions[ 0]
          visit_date @tested_date
        end

        it{ shows @tested_date}
        specify{ @booked_user.should be_booked( @tested_cd.sessions[ 0])}
        it{ within( :id, @tested_id
                  ){ should have_content( @booked_user.name)}}
        it{ within( :id, @tested_id
                  ){ should_not have_link( @booked_user.name)}}
      end
    end
  end

  context "when not admin" do

    shared_examples_for "unbooked" do
      # @tested_id, @first_date, @cd
      it_behaves_like "on court_days index page"
      it{ should_not have_selector( "select")}
      it{ should_not have_selector( "textarea")}
      it{ within( :id, @tested_id){
          should_not have_selector( "input[value='#{ t( "general.save")}']")}}
      it{ within( :id, date_session_to_id( @cd.date, :morning)){
            should have_selector( "input[value='#{ t( "booking.book.label",
                                  session: session_to_label( :morning))}']")}}
      it{ within( :id, date_session_to_id( @cd.date, :morning)){
            should have_content(
              "(#{ t( 'court_session.need.left.short',
                   count: @cd.sessions[ 0].need -
                            @cd.sessions[ 0].bookings.count)})")}}
      it{ within( :id, date_session_to_id( @cd.date, :afternoon)){
            should have_selector( "input[value='#{ t( "booking.book.label",
                                session: session_to_label( :afternoon))}']")}}
      it{ within( :id, date_session_to_id( @cd.date, :afternoon)){
            should have_content( "(#{ t( 'court_session.need.left.short',
                                         count: @cd.sessions[ 1].need -
                                        @cd.sessions[ 1].bookings.count)})")}}

      it "has no controls when nothing to book" do
        test_dates( @first_date) do |date, show|
          if show
            if date != @cd.date
              within( :id, "court-day-#{ date}") do
                should_not have_selector( "input[value='#{
                    t( 'booking.book.label', session: session_to_label( :morning))}']")
                should_not have_selector( "input[value='#{
                  t( 'booking.book.label', session: session_to_label( :afternoon))}']")
              end
            end
          else
            should_not have_selector( "div[id='court-day-#{ date}']")
          end
        end
      end
    end

    before do
      @user = create_test_user( name: "Normal",
                                email: "normal@example.com")
      fake_log_in @user
      @tested_id = @cd_id
      visit_date @cd.date
    end

    it_behaves_like "any user"
    it{ within( :id, @cd_id){ should have_content( t( 'general.cwday')[ @cd.date.cwday])}}
    it_behaves_like "unbooked"
    it_behaves_like "disabled link"

    context "booking" do

      def login_other_user
        @other = create_test_user( name: "En Annan",
                                   email: "en.annan@example.com")
        fake_log_in @other
      end

      shared_examples_for "any booking button click" do
        #  @tested_id, @value_book, @value_unbook

        it_behaves_like "on court_days index page"
        it{ within( :id, @tested_id){ should have_content( @user.name)}}
        it{ within( :id, @tested_id){ should_not have_link( @user.name)}}
        it{ within( :id, @tested_id){
          should_not have_selector( "input[value='#{ @value_book}']")}}
        it{ within( :id, @tested_id){
          should have_selector( "input[value='#{ @value_unbook}']")}}

        context "when overbooked" do
          before do
            @cd.sessions.each{ |s| s.update_attribute :need, 0}
            visit court_days_path
          end
          it{ within( :id, @tested_id){
                should have_selector( "span[class='overbooked']",
                                text: "(#{ t( 'court_session.need.over')})")}}
        end

        context "when unbooked" do
          before{ within( :id, @tested_id){ click_button @value_unbook}}
          it_behaves_like "unbooked"
        end
      end

      shared_examples_for "any other user" do
        it_behaves_like "on court_days index page"
        it{ within( :id, @tested_id){
          should_not have_selector( "input[value='#{ @value_unbook}']")}}
      end

      context "last" do

        before do
          @tested_id = @cd_id
          @value_book = t( 'booking.book.label',
                           session: session_to_label( :morning))
          @value_unbook = t( "booking.unbook.label",
                             session: session_to_label( :morning))
          @morning_id = date_session_to_id @cd.date, :morning
          visit_date @first_date
          within( :id, @tested_id){ click_button @value_book}
        end

        it_behaves_like "any booking button click"
        it{ within( :id, @morning_id){ should_not have_content(
                t( "court_session.need.left.short", count: 0))}}

        context "switch user" do
          before do
            login_other_user
            visit_date @first_date
          end
          it_behaves_like "any other user"
          it{ within( :id, @tested_id){
              should_not have_selector( "input[value='#{ @value_book}']")}}
        end
      end

      context "not last" do

        before do
          @tested_id = @cd_id
          @value_book = t( "booking.book.label",
                           session: session_to_label( :afternoon))
          @value_unbook = t( "booking.unbook.label",
                             session: session_to_label( :afternoon))
          @afternoon_id = date_session_to_id @cd.date, :afternoon
          visit_date @first_date
          within( :id, @tested_id){ click_button @value_book}
        end

        it_behaves_like "any booking button click"
        it{ within( :id, @afternoon_id){ should have_content(
                "(#{ t( 'court_session.need.left.short', count:
                @cd.sessions[ 1].need - @cd.sessions[ 1].bookings.count)})")}}

        context "switch user" do
          before do
            login_other_user
            visit_date @first_date
          end
          it_behaves_like "any other user"
          it{ within( :id, @cd_id){
            should have_selector( "input[value='#{ @value_book}']")}}
        end
      end

      context "overbooked" do

        before do
          visit_date @first_date
          @cd.sessions[ 0].update_attribute :need, 0
          @value_book = t( "booking.book.label",
                           session: session_to_label( :morning))
          within( :id, @cd_id){ click_button @value_book}
        end

        specify{ @cd.sessions[ 0].bookings.count.should == 0}
        it{ should have_selector( "div.alert.alert-error")}
      end

      context "future" do

        before do
          @tested_date = @cd.date + (1 + rand( 5)) * 7
          create_and_visit_tested_date
          @value_book = t( "booking.book.label",
                           session: session_to_label( :morning))
          @value_unbook = t( "booking.unbook.label",
                             session: session_to_label( :morning))
          within( :id, @tested_id){ click_button @value_book}
        end

        it{ shows @tested_date}
        it{ within( :id, @tested_id){ should_not have_selector(
                "input[value='#{ @value_book}']")}}
        it{ within( :id, @tested_id){ should have_selector(
                "input[value='#{ @value_unbook}']")}}

        context "unbooking" do
          before{ within( :id, @tested_id){ click_button @value_unbook}}
          it{ shows @tested_date}
          it{ within( :id, @tested_id){ should have_selector(
                  "input[value='#{ @value_book}']")}}
          it{ within( :id, @tested_id){ should_not have_selector(
                  "input[value='#{ @value_unbook}']")}}
        end
      end
    end
  end

  context "other court user" do
    before do
      other = User.find_by_court_id court_other
      unless CourtSession.find_all_by_date_and_court_id(
                            @cd.date, court_other.id).count > 0
        create_test_court_day court: court_other, date: @cd.date,
                              note: "Other note"
      end
      fake_log_in other, "bad_pw"
      visit_date @cd.date
    end
    it{ within( :id, @cd_id){ should_not have_content( @cd.note.text)}}
  end

  context "when admin" do

    before do
      @admin = create_test_user( name: "Admin",
                                 email: "admin@example.com",
                                 role: "admin")
      @user = @admin  # for any court admin and disabled link
      fake_log_in @admin
    end

    it_behaves_like "any court admin"
    it_behaves_like "disabled link"
  end

  context "when master" do

    before do
      @admin = create_test_user( name: "Master",
                                 email: "master@example.com",
                                 role: "master")
      @user = @admin  # for any court admin and disabled link
      fake_log_in @admin
    end

    it_behaves_like "any court admin"
    it_behaves_like "disabled link"
  end
end

