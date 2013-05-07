# encoding: UTF-8

require "generators/data"
include Generators::Data

namespace :db do
  COURT_COUNT = 3
  USER_COUNT = 5
  COURT_DAY_COUNT = 30
  desc "Fill database with sample data"

  task populate: :environment do

    puts "==  Create courts ============================================================"
    COURT_COUNT.times{ |c| court =
                             Court.create name: "Domstol #{ c + 1}"}
    puts "  #{ COURT_COUNT} courts created"

    puts "==  Create users ============================================================="
    master = User.create(
                    court:    Court.find_by_name( "Domstol 2"),
                    email:    "master@example.com",
                    name:     "Webbmaster",
                    role:     "master",
                    password: "master",
                    password_confirmation: "master")
    puts "  webmaster created at Domstol 2"
    Court.all.each{ |court|
      admin = User.create(
                     court:    court,
                     email:    "admin@example.com",
                     name:     "Admin #{ court.name}",
                     role:     "admin",
                     password: "admini",
                     password_confirmation: "admini")}
    puts "  #{ COURT_COUNT} court admins created"
    Court.all.each do |court|
      USER_COUNT.times{ |u|
        user = User.create(
                      court:    court,
                      email:    "vs#{ u + 1}@example.com",
                      name:     "Vittnesstöd #{ u + 1}", 
                      role:     "normal",
                      password: "vittne",
                      password_confirmation: "vittne")}
      puts "  #{ USER_COUNT} normal users created at #{ court.name}"
    end

    puts "==  Create court days ========================================================"
    generate_court_days(
      CourtDay.monday( Date.current - (COURT_DAY_COUNT / 10) * 7),
      COURT_DAY_COUNT, *Court.all
    ) do |court, sessions, notes|
      puts "  #{ COURT_DAY_COUNT} dates initialized at #{ court.name
               } (#{ sessions} sessions, #{ notes} notes)"
    end

    puts "==  Create bookings =========================================================="
    generate_bookings( *Court.all) do |court, bookings, unbooked|
      puts "  #{ bookings} bookings created at #{
                                 court.name} (#{ unbooked} sessions unbooked)"
    end
    puts "== done"
  end
end

