
namespace :db do
  desc "Fill database with sample data"
  task :populate => :environment do
    User.create!( :name => "Administratör",
                  :email => "anders1lindeberg@gmail.com",
                  :password => "admini",
                  :password_confirmation => "admini").toggle!( :admin)
    99.times do |n|
      name = "Ex #{ n + 1} Empel"
      email = "ex.#{ n + 1}.empel@exempel.se"
      User.create!( :name => name,
                    :email => email,
                    :password => "bokning",
                    :password_confirmation => "bokning")
    end
  end
end

