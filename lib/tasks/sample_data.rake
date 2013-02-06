
namespace :db do
  USER_COUNT = 20
  COURT_DAY_COUNT = 30
  desc "Fill database with sample data"
  task :populate => :environment do
    User.create!( :name => "Administratör",
                  :email => "anders1lindeberg@gmail.com",
                  :password => "admini",
                  :password_confirmation => "admini").toggle!( :admin)
    (USER_COUNT - 1).times do |n|
      name = "Ex #{ n + 1} Empel"
      email = "ex.#{ n + 1}.empel@exempel.se"
      User.create! :name => name, 
                   :email => email,
                   :password => "bokning",
                   :password_confirmation => "bokning"
    end
    first_date = Date.today - (COURT_DAY_COUNT / 10) * 7
    first_date -= first_date.cwday - 1
    incr = 0
    COURT_DAY_COUNT.times do |n|
      weeks, days = incr.divmod( 5)
      date = first_date + 7 * weeks + days
      puts date
      attrs = { :date => date}
      morning = rand( 3) == 0 ? 0 : 1 + rand( PARALLEL_SESSIONS_MAX)
      attrs[ :morning] = morning
      afternoon = rand( 3) == 0 ? 0 : 1 + rand( PARALLEL_SESSIONS_MAX)
      attrs[ :afternoon] = afternoon
      if n == 11
        attrs[ :notes] = %Q$En lång text med en radbrytning här ->\r\noch så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare$ 
      elsif (morning == 0 && afternoon == 0) || rand( 3) > 0
        attrs[ :notes] = "Fri text nummer #{ n + 1}"
      end
      CourtDay.create! attrs
      incr += rand( 2) + 1
    end
  end
end

