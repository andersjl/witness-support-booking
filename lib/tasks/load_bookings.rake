
namespace :db do
  BOOKINGS = <<-END_BOOKINGS
    users

    AL anders.lindeberg@telia.com
    AM agneta.magnusson@me.com
    AP alexandra.popoff@hotmail.com
    BH bengt@hellborg.net
    BI boigeborn@msn.com
    CFV carina_varttinen@hotmail.com
    DA danja.andersson@hotmail.com
    EF emma.fransson
    EM emma-martinsson@hotmail.com
    JH jhellgren@me.com
    LDF l.dohrnfalk@hotmail.com
    LF lisa.feldthusen@hotmail.com
    LH lisbethholmdahl@tele2.se
    LR linn.rosengard@hotmail.com
    MB vittnesstod.stockholm@gmail.com
    MFS margaretafallmans@gmail.com
    MH margareta@hellborg.net
    MHL lindeberg.mats@telia.com
    MNL manuelalindvall@hotmail.com
    MRL maria.lindblom08@telia.com
    MM anmama@telia.com
    MR margareta.regnstrom@bredband.net
    RM ruth.mekonen@hotmail.com
    SA sofie.abdsaleh@gmail.com
    SK knutsson_sanna@hotmail.com
    SÅ siri.ahlmans@hotmail.se

    bookings

    0318 AP ; BH ; Malin utbildning fm Södertörns tingsrätt / Föreläsn EXPO Södertörns tingsrätt
    0319 SÅ JH ; X MFS ; Utbildning heldag!
    0320 EF DA ; MHL AM
    0321 MRL MH ; X MR ; Budgetmöte
    0322 X ; X
    0325 MRL ; LR
    0326 MH LR ; AM LDF 
    0327 X X ; MHL BH
    0328 X X ; ; OBS! Skärtorsdag, oklart hur bemanningen ser ut
    0329 ; ; LÅNGFREDAG
    0401 ; ; ANNANDAG PÅSK
    0402 BH X ; EM EF
    0403 LH SK ; MHL X
    0404 MH X ; EF X
    0405 LF ; EM
    0408 BH ; X
    0409 CFV X ; X X
    0410 X X ; MHL X
    0411 LH MH ; LF X
    0412 X ; JH
    0415 BH ; MNL LDF
    0416 SK X ; X X
    0417 LH X ; X MHL
    0418 X X ; X X
    0419 X ; EM
  END_BOOKINGS

  desc "Load bookings from static data"
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
    state = :start
    users = { }
    BOOKINGS.each do |line|
      next if line.blank?
      line.strip!
      if [ "users", "bookings"].include? line
        state = line.intern
      elsif state == :users
        initials, email = line.split " "
        users[ initials] = User.find_by_email email
      elsif state == :bookings
        date_morning, afternoon, notes = line.split ";"
        date_morning = date_morning.split " "
        date = date_morning.shift
        morning = date_morning
        afternoon = afternoon ? afternoon.split( " ") : [ ]
        notes.strip! if notes
        puts [ line, date].inspect
        court_day =
          CourtDay.create! :date => Date.parse( "2013#{ date.strip}"),
                           :morning => morning.count,
                           :afternoon => afternoon.count,
                           :notes => notes
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
