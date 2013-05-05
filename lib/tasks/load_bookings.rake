# encoding: UTF-8

namespace :db do

  BOOKINGS = <<-END_BOOKINGS
    users

    AA amanda89a@hotmail.com
    AA2 agnesaronsson@yahoo.se
    AB anita.barrsveden@glocalnet.net
    AJ annakarin.jannisa.8660@student.uu.se
    AV annavikstrom@live.se
    ED ewa.dalgren@gmail.com
    EE eva@ehrstedt.net
    EJ erica_jimenez@hotmail.com
    EP ejan.petren@gmail.com
    MB mia.burstein@telia.com
    MH may.henriksson@bredband.net
    MK monicaswe@hotmail.com
    MO margareta.olofsson40@gmail.com
    NH vittnesstod-sodertorn@farsta.boj.se
    PT mwa89a@hotmail.com
    SF saara_fahmy@hotmail.com
    SM susan.merwanson@hotmail.com

    bookings

    0422 X ; EP ; Natalie med Susan fm Ejan med Erica em
    0424 X ; MK ; May fm
    0425 EE ; MO
    0429 AA2 AJ ; X ; Natalie med Mia em
    0430 MK ; ; Halvdag
    0501 ; ; Röd dag
    0502 AJ ; AJ
    0506 X ; X ; Saara fm Natalie med Erica em
    0507 PT ; EP
    0508 X ; ; Sanna fm Halvdag
    0509 ; ; Röd dag
    0513 X ; X
    0514 X ; X
    0515 X ; X
    0516 X ; MO
  END_BOOKINGS

  desc "Load bookings from static data"
  task load_bookings: :environment do
    sodert = Court.find_by_name "Södertörns tingsrätt"
    state = :start
    users = { }
    BOOKINGS.each_line do |line|
      next if line.blank?
      line.strip!
      if [ "users", "bookings"].include? line
        state = line.intern
      elsif state == :users
        initials, email = line.split " "
        users[ initials] = User.find_by_email_and_court_id email, sodert
      elsif state == :bookings
        date_morning, afternoon, notes = line.split ";"
        date_morning = date_morning.split " "
        date = date_morning.shift
        morning = date_morning
        afternoon = afternoon ? afternoon.split( " ") : [ ]
        notes.strip! if notes
        court_day =
          CourtDay.create! court: sodert,
                           date: Date.parse( "2013#{ date.strip}"),
                           morning: morning.count,
                           afternoon: afternoon.count,
                           notes: notes
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
