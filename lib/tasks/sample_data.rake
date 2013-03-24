# encoding: UTF-8

namespace :db do
  COURT_COUNT = 3
  USER_COUNT = 5
  COURT_DAY_COUNT = 30
  desc "Fill database with sample data"

  task :populate => :environment do

    puts "==  Create courts ============================================================"
    COURT_COUNT.times{ |c| court = Court.create! :name => "Domstol #{ c + 1}"}
    puts "  #{ COURT_COUNT} courts created"

    puts "==  Create users ============================================================="
    master = User.new :name => "Webbmaster",
                      :email => "master@example.com",
                      :password => "master",
                      :password_confirmation => "master"
    master.court = Court.find_by_name "Domstol 2"
    master.role = "master"
    master.save!
    puts "  webmaster created at Domstol 2"
    Court.all.each do |court|
      admin = User.new :name => "Admin #{ court.name}",
                       :email => "admin@example.com",
                       :password => "admini",
                       :password_confirmation => "admini"
      admin.court = court
      admin.role = "admin"
      admin.save!
    end
    puts "  #{ COURT_COUNT} court admins created"
    Court.all.each do |court|
      USER_COUNT.times do |u|
        user = User.new :name => "Vittnesstöd #{ u + 1}", 
                        :email => "vs#{ u + 1}@example.com",
                        :password => "vittne",
                        :password_confirmation => "vittne"
        user.court = court
        user.role = "normal"
        user.save!
      end
      puts "  #{ USER_COUNT} normal users created at #{ court.name}"
    end

    puts "==  Create court days ========================================================"
    first_date = Date.today - (COURT_DAY_COUNT / 10) * 7
    first_date -= first_date.cwday - 1
    Court.all.each do |court|
      long_text = rand( COURT_DAY_COUNT)
      incr = 0
      COURT_DAY_COUNT.times do |d|
        weeks, days = incr.divmod( 5)
        attrs = { :date => first_date + 7 * weeks + days}
        morning = rand( 3) == 0 ? 0 : 1 + rand( PARALLEL_SESSIONS_MAX)
        attrs[ :morning] = morning
        afternoon = rand( 3) == 0 ? 0 : 1 + rand( PARALLEL_SESSIONS_MAX)
        attrs[ :afternoon] = afternoon
        if d == long_text
          attrs[ :notes] = %Q$En lång text med en radbrytning här ->\r\noch så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare$ 
        elsif (morning == 0 && afternoon == 0) || rand( 3) > 0
          attrs[ :notes] = "Fri text nummer #{ d + 1}"
        end
        court_day = CourtDay.new attrs
        court_day.court = court
        court_day.save!
        incr += rand( 2) + 1
      end
      puts "  #{ COURT_DAY_COUNT} dates initialized at #{ court.name}"
    end

    puts "==  Create bookings =========================================================="
    Court.all.each do |court|
      bookings = 0
      users = User.where( [ "court_id = ? and role = ?", court.id, "normal"])
      shortlist = users[ 0, 3]
      CourtDay.where( [ "court_id = ?", court.id]).each do |court_day|
        [ :morning, :afternoon].each do |session|
          court_day.send( session).times do
            user = (rand( 2) == 0 ? shortlist : users).choice
            if rand( 3) != 0 && !user.booked?( court_day, session)
              user.book! court_day, session
              bookings += 1
            end
          end
        end
      end
      puts "  #{ bookings} bookings created at #{ court.name}"
    end
    puts "== done"
  end
end

