# encoding: UTF-8

require "spec_helper"

describe "Court pages" do

  subject{ page}

  describe "index" do

    shared_examples_for "any listed court" do
      it{ within( :id, "court-#{ @court.id}"){
            should have_content @court.name}}
      it{ within( :id, "court-#{ @court.id}"){
            should have_link @court.link, :href => @court.link}}
      it{ within( :id, "court-#{ @court.id}"){
            should have_link "Ändra namn eller länk",
                             :href => edit_court_path( @court)}}
    end

    before do
      @master = create_test_user :email => "ma@ster", :name => "Master",
                                 :role => "master"
      courts = [ ]
      2.times do |round|
        users = rand( 2) + 1
        without_users = create_test_court :name => "Domstol #{ round}0"
        with_users = create_test_court :name => "Domstol #{ round}#{users}",
                                       :users => users
        if rand( 2) == 0
          courts << without_users << with_users
        else
          courts << with_users << without_users
        end
      end
      @court = courts.choice
      fake_log_in @master
      visit courts_path
    end

    it{ should have_selector(
      "title", :text => "#{ APPLICATION_NAME} | Domstolar")}
    it{ should have_selector( "h1", :text => "Domstolar")}
    it_behaves_like "any listed court"

    it "offers delete only for courts without users" do
      covered_has_users = false
      covered_has_no_users = false
      Court.all.each do |court|
        if court.users.count == 0
          covered_has_no_users = true
          within :id, "court-#{ court.id}" do
            should have_link "Ta bort", :href => court_path( court)
          end
        else
          covered_has_users = true
          within :id, "court-#{ court.id}" do
            should_not have_link "Ta bort", :href => court_path( court)
          end
        end
      end
      covered_has_users.should be_true
      covered_has_no_users.should be_true
    end

    context "deleting a court" do
      before do
        @court.users.destroy_all
        visit courts_path
      end
      specify{ within( :id, "court-#{ @court.id}"){
        expect{ click_on( "Ta bort")}.to change( Court, :count).by( -1)}}
    end

    context "should have input for new court" do
      it{ within( :id, "court-new"){
            should have_selector( "input#court_name", :value => "")}}
    end

    context "when defining a new court" do

      before do
        within :id, "court-new" do
          fill_in "court_name", :with => "New Court"
          fill_in "court_link", :with => "new.example.com"
        end
      end

      specify{ within( :id, "court-new"){
                 expect{ click_button "Spara"
                       }.to change( Court, :count).by( 1)}}

      context "then" do

        before do
          within( :id, "court-new"){ click_button "Spara"}
          @court = Court.find_by_name "New Court"
        end

        it{ should have_selector(
          "title", :text => "#{ APPLICATION_NAME} | Domstolar")}
        it_behaves_like "any listed court"
      end
    end
  end

  describe "update" do

    before do
      @master = create_test_user :email => "ma@ster", :name => "Master",
                                 :role => "master"
      fake_log_in @master
      create_test_court :count => 3
      @court = Court.all.choice
      visit edit_court_path( @court)
    end

    it{ should have_selector(
      "title", :text => "#{ APPLICATION_NAME} | #{ @court.name}")}
    it{ should have_selector( "h1", :text => "Ändra domstol #{ @court.name}")}
    it{ should have_selector "input[value='#{ @court.name}']"}
    it{ should have_selector "input[value='#{ @court.link}']"}

    context "when changing name and link" do
      before do
        @old_name = @court.name
        @old_link = @court.link
        fill_in "court_name", :with => "New Name"
        fill_in "court_link", :with => "http://example.com"
        click_button "Ändra"
        @court.reload
      end
      specify{ @court.name.should == "New Name"}
      specify{ @court.link.should == "http://example.com"}
      it{ should have_selector(
        "title", :text => "#{ APPLICATION_NAME} | Domstolar")}
      it{ within( :id, "court-#{ @court.id}"){
            should have_content @court.name}}
      it{ within( :id, "court-#{ @court.id}"){
            should have_link @court.link, :href => @court.link}}
      it{ within( :id, "court-#{ @court.id}"){
            should_not have_content @old_name}}
      it{ within( :id, "court-#{ @court.id}"){
            should_not have_content @old_link}}
    end
  end
end

