
namespace :db do
  desc "Load bookings from file"
  task :load_bookings => :environment do
    CourtDay.destroy_all
    User.all.each do |user|
      next if user.admin?
      if user.email == "vittnesstod.stockholm@gmail.com"
        user.update_attribute :role, "admin"
      else
        user.update_attribute :role, "normal"
      end
    end
    File.open( "tmp/maintenance/court_days_and_bookings.txt") do |f|
      state = :start
      users = { }
      f.each do |line|
        next if line.blank?
        line.strip!
        if [ "users", "bookings"].include? line
          state = line.intern
        elsif state == :users
          initials, email = line.split " "
          users[ initials] = User.find_by_email email
        elsif state == :bookings
          date_morning, afternoon = line.split ";"
          date_morning = date_morning.split " "
          date = date_morning.shift
          morning = date_morning
          afternoon = afternoon ? afternoon.split( " ") : [ ]
          court_day =
            CourtDay.create! :date => Date.parse( "2013#{ date.strip}"),
                             :morning => morning.count,
                             :afternoon => afternoon.count
          [ :morning, :afternoon].each do |session|
            eval( "#{session}").each do |user|
              next if user == "X"
              users[ user].book! court_day, session
            end
          end
        else
          raise "unknown state #{ state.inspect}"
        end
      end
    end
  end
end
