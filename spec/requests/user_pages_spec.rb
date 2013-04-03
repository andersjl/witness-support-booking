require "spec_helper"

describe "User pages" do

  before do
    @court = court_this
    @other_court = court_other
  end

  subject{ page}

  describe "sign_up process" do

    before{ visit sign_up_path}

    it{ should have_selector( "h1", :text => t( "users.new.title"))}
    it{ should have_selector( "title",
      :text => "#{ t( 'general.application')} | #{ t( 'users.new.title')}")}
    unless I18n.locale == :en
      it{ should have_selector( "label",
            :text => t( "activerecord.attributes.user.court"))}
      it{ should have_selector( "label",
            :text => t( "activerecord.attributes.user.name"))}
      it{ should have_selector( "label",
            :text => t( "activerecord.attributes.user.email"))}
      it{ should have_selector( "label",
            :text => t( "activerecord.attributes.user.password"))}
      it{ should have_selector( "label",
           :text => t( "activerecord.attributes.user.password_confirmation"))}
    end

    context "with invalid information" do
      it "should not create a user" do
        expect{ click_button t( "users.new.save")
              }.not_to change( User, :count)
      end
    end

    context "first user" do
      before do
        User.destroy_all
        Court.destroy_all
        visit sign_up_path
        select  t( "court.default"), :from => "user_court"
        fill_in "user_name",         :with => "Example User"
        fill_in "user_email",        :with => "user@example.com"
        fill_in "user_password",     :with => "foobar"
        fill_in "user_password_confirmation", :with => "foobar"
        click_button t( "users.new.save")
      end
      it "creates a user and a default court" do
        User.count.should == 1
        Court.count.should == 1
      end
      specify{ User.first.should_not be_enabled}
    end

    context "with valid information" do

      before do
        select  @court.name,     :from => "user_court"
        fill_in "user_name",     :with => "Example User"
        fill_in "user_email",    :with => "user@example.com"
        fill_in "user_password", :with => "foobar"
        fill_in "user_password_confirmation", :with => "foobar"
      end

      it "should create a user" do
        expect{ click_button t( "users.new.save")
              }.to change( User, :count).by( 1)
      end

      context "after saving the user" do
        before do
          click_button t( "users.new.save")
          @user = User.find_by_court_id_and_email( @court, "user@example.com")
        end
        it{ @user.should_not be_enabled}
        it{ should_not have_selector(
              "title", :text => "#{ t( 'general.application')} | ")}
        it{ should have_content(
              t( "static_pages.home.disabled", email: "user@example.com"))}
        it{ should have_selector( "div.alert.alert-success",
              :text => t( "user.created", name: @user.name))}
        it{ should have_link( @user.court.name, :href => @user.court.link)}
        it{ should_not have_link( t( "court_days.index.title"))}
        it{ should_not have_link( t( "users.index.title"))}
        it{ should have_link( t( "general.log_out"), :href => log_out_path)}
        it{ should_not have_link( t( "general.log_in"))}
        it "should send an email to admin"

        context "when enabled by admin" do

          before do
            @admin = create_test_user :court => @court, :email => "ad@min",
                                      :role => "admin", :name => "Admin"
            fake_log_in @admin
            visit users_path
            within( "li#user-#{ @user.id}"){
              click_link( t( "user.enable.label"))}
          end

          it{ @user.reload.should be_enabled}
          it "should send an email to the enabled user"

          context "flashes success" do
            it{ should have_selector( "div.alert.alert-success",
                                      :content => @user.name)}
            it{ should have_selector( "div.alert.alert-success",
                                      :content => @user.email)}
          end
        end
      end
    end
  end

  describe "index" do

    shared_examples_for "any admin" do  # @disabl, @normal, @admin

      it{ within( "li#user-#{ @disabl.id}"
                ){ should have_link( t( "users.index.rescue"),
                                     :href => edit_user_path( @disabl))}}
      it{ within( "li#user-#{ @normal.id}"
                ){ should have_link( t( "users.index.rescue"),
                                     :href => edit_user_path( @normal))}}
      it{ within( "li#user-#{ @admin.id}"
                ){ should_not have_content( t( "users.index.rescue"))}}

      it{ within( "li#user-#{ @disabl.id}"){ should have_link(
              t( "general.destroy"), :href => user_path( @disabl))}}
      it{ within( "li#user-#{ @normal.id}"){ should have_link(
              t( "general.destroy"), :href => user_path( @normal))}}
      it{ within( "li#user-#{ @admin.id}"){ should_not have_content(
              t( "general.destroy"))}}
      it "delete another user" do
        within( "li#user-#{ @disabl.id}"){ expect{ click_link(
          t( "general.destroy"))}.to change( User, :count).by( -1)}
        within( "li#user-#{ @normal.id}"){ expect{ click_link(
          t( "general.destroy"))}.to change( User, :count).by( -1)}
      end

      it{ within( "li#user-#{ @disabl.id}"
                ){ should_not have_content( t( "user.disable.label"))}}
      it{ within( "li#user-#{ @normal.id}"){ should have_link(
            t( "user.disable.label"), :href => disable_user_path( @normal))}}
      it{ within( "li#user-#{ @admin.id}"
                ){ should_not have_content( t( "user.disable.label"))}}
      it "disable a normal user" do
        within( "li#user-#{ @normal.id}"
              ){ click_link( t( "user.disable.label"))}
        @normal.reload.role.should == "disabled"
      end

      it{ within( "li#user-#{ @disabl.id}"){ should have_link(
            t( "user.enable.label"), :href => enable_user_path( @disabl))}}
      it{ within( "li#user-#{ @normal.id}"
                ){ should_not have_content( t( "user.enable.label"))}}
      it{ within( "li#user-#{ @admin.id}"
                ){ should_not have_content( t( "user.enable.label"))}}
      it "enable a disabled user" do
        within( "li#user-#{ @disabl.id}"
              ){ click_link( t( "user.enable.label"))}
        @disabl.reload.role.should == "normal"
      end
    end

    before do
      @user = create_test_user( :court => @court, :count => 3).sample
      fake_log_in @user
      visit users_path
    end

    it{ should have_selector( "title",
         text: "#{ t( 'general.application')} | #{ t( 'users.index.title')}")}
    it{ should have_selector( "h1",
          text: t( "users.index.heading.long", court: @user.court.name))}
    it{ should_not have_content( t( "users.index.rescue"))}
    it{ should_not have_content( t( "general.destroy"))}
    it{ should_not have_content( t( "user.disable.label"))}
    it{ should_not have_content( t( "user.enable.label"))}
    it{ should_not have_content( t( "user.promote.label"))}

    context "when clicking a user" do
      before do
        @other = User.where( "id != ? and court_id = ?",
                             @user.id, @user.court.id).sample
        click_link( @other.name)
      end
      it{ should have_selector( "title",
            :text => t( "general.application") + " | #{ @other.name}")}
    end

    it "lists each user with link" do
      User.order_by_role_and_name( @court).each do |user|
        page.should have_selector( "li", :text => user.name)
        page.should have_link( user.name)
        page.should_not have_content( user.email)
      end
    end

    context "as admin" do

      before do
        @disabl = create_test_user :court => @court,   :email => "dis@abl",
                                   :name => "Disabl",  :role  => "disabled"
        @normal = @user
        @admin  = create_test_user :court => @court,   :email => "ad@min",
                                   :name => "Admin",   :role  => "admin"
        fake_log_in @admin
        visit users_path
      end

      it_behaves_like "any admin"

      it{ should_not have_content( t( "user.promote.label"))}
    end

    context "as master" do
      before do
        @disabl = create_test_user :court => @court,   :email => "dis@abl",
                                   :name => "Disabl",  :role  => "disabled"
        @normal = @user
        @courta = create_test_user :court => @court,   :email => "ad@min",
                                   :name => "Court A", :role  => "admin"
        @admin  = create_test_user :court => @other_court, :email => "m@st",
                                   :name => "Master",  :role  => "master"

        fake_log_in @admin  # has role "master"!
        visit users_path
      end

      it{ should have_selector "h1", text: t( "users.index.heading.short")}

      it_behaves_like "any admin"

      [ "disabl", "normal", "courta", "admin"].each do |u|
        it "has link to @#{ u}.court" do
          user = eval "@#{ u}"
          court = user.court
          within( "li#user-#{ user.id}"
                ){ should have_link( court.name, :href => court.link)}
        end
      end

      it{ within( "li#user-#{ @courta.id}"
                ){ should have_link( t( "users.index.rescue"),
                                     :href => edit_user_path( @courta))}}

      it{ within( "li#user-#{ @courta.id}"){ should have_link(
              t( "general.destroy"), :href => user_path( @courta))}}
      it "delete a court admin" do
        within( "li#user-#{ @courta.id}"){
          expect{ click_link( t( "general.destroy"))
                }.to change( User, :count).by( -1)}
      end

      it{ within( "li#user-#{ @courta.id}"){ should have_link(
            t( "user.disable.label"), :href => disable_user_path( @courta))}}
      it "disable a court admin" do
        within( "li#user-#{ @courta.id}"
              ){ click_link( t( "user.disable.label"))}
        @courta.reload.role.should == "disabled"
      end

      it{ within( "li#user-#{ @courta.id}"
                ){ should_not have_content( t( "user.enable.label"))}}

      it{ within( "li#user-#{ @disabl.id}"){ should have_link(
             t( "user.promote.label"), :href => promote_user_path( @disabl))}}
      it{ within( "li#user-#{ @normal.id}"){ should have_link(
             t( "user.promote.label"), :href => promote_user_path( @normal))}}
      it{ within( "li#user-#{ @courta.id}"){ should_not have_content(
              t( "user.promote.label"))}}
      it{ within( "li#user-#{ @admin.id}"){ should_not have_content(
              t( "user.promote.label"))}}
      it "promote a disabled user" do
        within( "li#user-#{ @disabl.id}"
              ){ click_link( t( "user.promote.label"))}
        @disabl.reload.role.should == "admin"
      end
      it "promote a normal user" do
        within( "li#user-#{ @normal.id}"
              ){ click_link( t( "user.promote.label"))}
        @normal.reload.role.should == "admin"
      end
    end
  end

  describe "show" do

    before do
      @user = create_test_user
      fake_log_in @user
      visit user_path( @user)
    end

    shared_examples_for "viewing any user" do
      it{ should have_selector( "h1", text: @shown.name)}
      it{ should have_selector(
        "title", :text => "#{ t( 'general.application')} | #{ @shown.name}")}
    end

    shared_examples_for "all execept master viewing self" do
      it{ should_not have_content( t( "shared.dump.prompt"))}
      it{ should_not have_content( t( "shared.load.prompt"))}
    end

    context "self" do
      before{ @shown = @user}
      it_behaves_like "viewing any user"
      it{ should have_content( @user.email)}
      it{ should have_link( t( "general.edit"),
                            :href => edit_user_path( @user))}
      it_behaves_like "all execept master viewing self"
    end

    context "other user" do
      before do
        @other = create_test_user :court => @court, :name => "Other",
                                  :email => "ot@her"
        @shown = @other
        visit user_path( @other)
      end
      it_behaves_like "viewing any user"
      it{ should_not have_content( @other.email)}
      it_behaves_like "all execept master viewing self"
    end

    context "admin" do

      before do
        @admin = create_test_user :court => @court, :name => "Ad Min",
                                  :email => "ad@min", :role => "admin"
        fake_log_in @admin
        visit user_path( @admin)
      end

      context "viewing self" do
        before{ @shown = @admin}
        it_behaves_like "viewing any user"
        it{ should have_content( @admin.email)}
        it_behaves_like "all execept master viewing self"
      end

      context "viewing other" do
        before do
          visit user_path( @user)
          @shown = @user
        end
        it_behaves_like "viewing any user"
        it_behaves_like "all execept master viewing self"
      # below is not a requirement?
      # it{ should have_content( @shown.email)}
      # it{ should_not have_content( @shown.email)}
      end
    end

    context "master" do

      before do
        @admin = create_test_user :court => @court, :name => "Ad Min",
                                  :email => "ad@min", :role => "admin"
        @master = create_test_user :court => court_other, :name => "Master",
                                   :email => "ma@ster", :role => "master"
        fake_log_in @master
        visit user_path( @master)
      end

      context "viewing self" do
        before{ @shown = @master}
        it_behaves_like "viewing any user"
        it{ should have_content @master.email}
        it{ should have_link t( "courts.index.title"), :href => courts_path}
        it{ should have_link t( "shared.dump.prompt"), :href => database_path}
        it{ should have_link t( "shared.load.prompt"),
                                :href => new_database_path}
      end

      (USER_ROLES - [ "master"]).each do |role|
        context "viewing other #{ role}" do
          before do
            @shown = User.where( "role = ?", role).sample ||
              create_test_user( :email => role, :role => role)
            visit user_path( @shown)
          end
          it_behaves_like "viewing any user"
          it{ should have_content( @shown.email)}
          it_behaves_like "all execept master viewing self"
          it{ should_not have_content t( "courts.index.title")}
        end
      end

      context "saving database" do
        # file content is tested with the new_database_path request
        before{ click_link t( "shared.dump.prompt")}
        context "page.response_headers[ 'Content-Type']" do
          it{ page.response_headers[ "Content-Type"].should == "text/xml"}
        end
      end
    end
  end

  describe "edit" do

    def self.admin_examples
      # @editor, @edited, @new_email, @new_name, @new_pw

      context "court admin" do

        before do
          visit edit_user_path( @edited)
        end

        it_behaves_like "editing any user"

        context "changing other attributes" do

          before do
            @old_court_id = @edited.court.id
            @old_email    = @edited.email
            @old_name     = @edited.name
            fill_in "user_email",                 :with => @new_email
            fill_in "user_name",                  :with => @new_name
            fill_in "user_password",              :with => @new_pw
            fill_in "user_password_confirmation", :with => @new_pw
            click_button t( "users.edit.save")
            @edited.reload
          end

          specify{ @edited.court.id.should  == @old_court_id}
          specify{ @edited.email.should     == @old_email}
          specify{ @edited.name.should      == @old_name}
        end

        context "changing password" do

          before do
            @old_court_id = @edited.court.id
            @old_email    = @edited.email
            @old_name     = @edited.name
            @old_pw       = @edited.password
            fill_in "user_password",              :with => @new_pw
            fill_in "user_password_confirmation", :with => @new_pw
            click_button t( "users.edit.save")
            @edited.reload
          end

          it{ should have_selector( "title", text: "#{
                  t( 'general.application')} | #{ t( 'users.index.title')}")}
          it{ within( "div.alert.alert-success"){ should have_content(
                  t( "user.changed.password", name: @edited.name))}}
          specify "still logged in as court admin" do
            click_link( @editor.name)
            should have_content( @editor.email)
          end
          it_behaves_like "password change"
          specify{ @edited.court.id.should  == @old_court_id}
          specify{ @edited.email.should     == @old_email}
          specify{ @edited.name.should      == @old_name}
        end
      end
    end

    before do
      @user = create_test_user :court => @court
      @old_pw = @user.password
      @new_name = "Nytt Namn"
      @new_email = "ny@mejl"
      @new_pw = "new_pw"
    end

    shared_examples_for "editing any user" do
      it{ should have_selector( "h1", text: t( "users.edit.title",
                                               name: @edited.name))}
      it{ should have_selector( "title", text: "#{ t( "general.application")
                         } | #{ t( "users.edit.title", name: @edited.name)}")}
    end

    shared_examples_for "password change" do
      # @edited, @old_pw, @new_pw
      it "old password does not work" do
        fake_log_in @edited, @old_pw
        should have_selector( "title",
          text: "#{ t( 'general.application')} | #{ t( 'general.log_in')}")
        should have_selector( "div.alert.alert-error")
      end
      it "new password works" do
        fake_log_in @edited, @new_pw
        should have_selector( "title", text: "#{ t( 'general.application')
                                } | #{ t( 'court_days.index.title')}")
      end
    end

    context "yourself" do

      before do
        fake_log_in @user
        visit edit_user_path( @user)
        @edited = @user
      end

      it_behaves_like "editing any user"

      describe "with invalid password" do
        before{ click_button t( "users.edit.save")}
        it{ should have_selector( "div.alert.alert-error")}
      end

      describe "email collision" do
        before do
          create_test_user :email => @new_email
          fill_in "user_email",                 :with => @new_email
          fill_in "user_name",                  :with => @new_name
          fill_in "user_password",              :with => @new_pw
          fill_in "user_password_confirmation", :with => @new_pw
          click_button t( "users.edit.save")
        end
        it{ should have_selector( "div.alert.alert-error")}
      end

      describe "email collision but different court" do
        before do
          other = create_test_user :court => court_other,
                                   :email => @new_email
          fill_in "user_email",                 :with => @new_email
          fill_in "user_name",                  :with => @new_name
          fill_in "user_password",              :with => @new_pw
          fill_in "user_password_confirmation", :with => @new_pw
          click_button t( "users.edit.save")
        end
        it{ should_not have_selector( "div.alert.alert-error")}
      end

      describe "with valid information" do

        before do
          fill_in "user_email",                 :with => @new_email
          fill_in "user_name",                  :with => @new_name
          fill_in "user_password",              :with => @new_pw
          fill_in "user_password_confirmation", :with => @new_pw
          click_button t( "users.edit.save")
          @user.reload
          @edited = @user
        end

        it_behaves_like "password change"
        it{ should have_selector( "title", text: "#{ t( 'general.application')
                                    } | #{ t('court_days.index.title')}")}
        it{ within( "div.alert.alert-success"
                  ){ should have_content( t( "user.changed.message"))}}
        it{ should have_link( t( "general.log_out"), :href => log_out_path)}
        specify{ @user.name.should  == @new_name}
        specify{ @user.email.should == @new_email}
      end
    end

    context "admin" do

      before do
        @admin = create_test_user :court => @court, :role => "admin",
                                  :name => "Admin", :email => "ad@min"
        fake_log_in @admin
        @editor = @admin
        @edited = @user
      end

      admin_examples

      context "trying to edit user on other court" do
        before do
          @other_user = create_test_user( :court => court_other, :count => 3
                                        ).sample
          visit edit_user_path @other_user
        end
        it{ should_not have_selector( "h1", :text => @other_user.name)}
      end
    end

    context "master" do

      before do
        @master = create_test_user :court => @court, :email => "ma@ster",
                                   :name => "Master", :role => "master"
        fake_log_in @master
        @editor = @master
      end

      context "editing user at own court" do
        before{ @edited = @user}
        admin_examples
      end

      context "editing user on other court" do
        before do
          @edited = create_test_user( :court => court_other, :count => 3
                                    ).sample
          @old_pw = @edited.password
        end
        admin_examples
      end
    end
  end
end

