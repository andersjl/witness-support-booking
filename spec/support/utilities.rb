
def t( key, opts = { })
  I18n.translate key, opts
end

def known_problem
  yield
rescue RSpec::Expectations::ExpectationNotMetError => e
  pending "#{ e.message} - known problem"
end

def clear_models
  [ Booking, CourtDayNote, CourtSession, User, Court].
    each{ |m| m.send :delete_all}
end

def court_this; court_default "This Court" end
def court_other; court_default "Other Court" end

def court_default( name)
  result = Court.find_by_name( name)
  return result if result
  create_test_court( name: name) unless name == "Other Court"
  other_court = Court.find_by_name( "Other Court")
  unless other_court
    other_court = create_test_court( name: "Other Court")
    other_court_user = create_test_user court:    other_court,
                                        email:    "other@example.com",
                                        name:     "Other User",
                                        password: "bad_pw"
    other_court_session =
      create_test_court_session court: other_court, need: 1
    Booking.create! user: other_court_user, court_session: other_court_session
  end
  Court.find_by_name( name)
end

def create_test_court( opts = { })
  opts = opts.dup
  count = opts.delete( :count) || 1
  users = opts.delete( :users)
  do_not_save = opts.delete :do_not_save
  opts[ :name] ||= "Domstol"
  opts[ :link] ||= "#"
  if count == 1
    create_test_court_do opts, do_not_save, users
  else
    count.times.collect{ |no| create_test_court_do opts, do_not_save,
                                                   users, (no + 1).to_s}
  end
end
def create_test_court_do( attrs, do_not_save, users, extra = nil)
  used = attrs.dup
  used[ :name] += " #{ extra.to_s}" if extra
  used[ :link] += extra.to_s if extra
  result = Court.new( used)
  result.save! unless do_not_save
  if users && users > 0
    create_test_user court: result, count: users, do_not_save: do_not_save
  end
  result
end
private :create_test_court_do

def create_test_user( opts = { })
  opts = opts.dup
  count = opts.delete( :count) || 1
  do_not_save = opts.delete :do_not_save
  opts[ :court] ||= court_this
  opts[ :email] ||= "ex@empel.se"
  opts[ :name] ||= "Ex Empel"
  opts[ :password] ||= "bad_pw"
  opts[ :password_confirmation] ||= opts[ :password]
  opts[ :role] ||= "normal"
  if count == 1
    create_test_user_do opts, do_not_save
  else
    count.times.collect{ create_test_user_do opts, do_not_save}
  end
end
def create_test_user_do( attrs, do_not_save, extra = nil)
  used = attrs.dup
  extra = 0
  email = used[ :email]
  name = used[ :name]
  while User.find_by_court_id_and_email( used[ :court], used[ :email])
    extra += 1
    used[ :email] = extra.to_s + email
    used[ :name]  = extra.to_s + name
  end
  result = User.new( used)
  result.save! unless do_not_save
  result
end
private :create_test_user_do

def fake_log_in( user, password = nil)
  if page.first( "a", text: t( "general.log_out"))
    click_link( t( "general.log_out"))
  end
  visit log_in_path
  select user.court.name, from: "user_session_court_id"
  fill_in "user_session_email", with: user.email
  fill_in "user_session_password", with: password || user.password
  click_button t( "general.log_in")
  cookies[ :remember_token] = user.remember_token  # if not Capybara
end

def create_test_court_day( opts = { })
  opts = opts.dup
  count = opts.delete( :count) || 1
  opts[ :court] ||= court_this
  opts[ :date] ||= Date.current
  opts[ :date] = CourtDay.ensure_weekday opts[ :date]
  opts[ :sessions] ||= START_TIMES_OF_DAY_DEFAULT.collect{ |s| [ s, 1]}
  if count == 1
    create_test_court_day_do opts
  else
    count.times.collect{ create_test_court_day_do opts, :inc}
  end
end
def create_test_court_day_do( attrs, increment = false)
  sessions = attrs[ :sessions].collect do |start, need|
    create_test_court_session(
      do_not_save: attrs[ :do_not_save],
      court:       attrs[ :court],
      date:        attrs[ :date],
      start:       start,
      need:        need + rand( need + 1))
  end
  text = attrs[ :note] || (rand( 3) > 0 ? "Fri text" : nil)
  unless text.blank?
    note = create_test_court_day_note do_not_save: attrs[ :do_not_save],
                                      court: attrs[ :court],
                                      date: attrs[ :date], text: text
  end
  result = CourtDay.new court: attrs[ :court], date: attrs[ :date],
                        sessions: sessions, note: note
  if increment
    attrs[ :date] = Court_day.add_weekdays( attrs[ :date], rand( 2) + 1)
  end
  result
end
private :create_test_court_day_do

def create_test_court_session( opts = { })
  opts = opts.dup
  count = opts.delete( :count) || 1
  do_not_save = opts.delete :do_not_save
  opts[ :court] ||= court_this
  opts[ :date] ||= Date.tomorrow
  opts[ :start] ||= START_TIMES_OF_DAY_DEFAULT.sample
  while opts[ :date].cwday > 5 ||
      CourtSession.find_by_date_and_court_id_and_start(
                     opts[ :date], opts[ :court], opts[ :start])
    opts[ :date] += 1
  end
  opts[ :need] ||= 1
  if count == 1
    create_test_court_session_do opts, do_not_save
  else
    count.times.collect{ create_test_court_session_do opts, do_not_save, :inc}
  end
end
def create_test_court_session_do( attrs, do_not_save, increment = false)
  used = attrs.dup
  if increment
    old_time = attrs[ :date].to_time_in_current_zone + attrs[ :start]
    ix = START_TIMES_OF_DAY_DEFAULT.index( attrs[ :start])
    attrs[ :start] =
      if ix
        START_TIMES_OF_DAY_DEFAULT[ (ix + (rand( 3) == 0 ? 2 : 1)) %
                                      START_TIMES_OF_DAY_DEFAULT.count]
      else
        (attrs[ :start] + 1 + rand( 24 * 60 *60)) % (24 * 60 * 60)
      end
    while attrs[ :date].to_time_in_current_zone + attrs[ :start] <= old_time
      attrs[ :date] +=  1
    end
    used[ :need] = used[ :need] + rand( used[ :need] + 1)
  end
  used[ :need] = [ used[ :need], PARALLEL_SESSIONS_MAX].min
  if do_not_save
    CourtSession.new used
  else
    CourtSession.create! used
  end
end
private :create_test_court_session_do

def create_test_court_day_note( opts = { })
  opts = opts.dup
  count = opts.delete( :count) || 1
  do_not_save = opts.delete :do_not_save
  opts[ :court] ||= court_this
  opts[ :date] ||= Date.current
  while opts[ :date].cwday > 5 ||
          CourtDayNote.find_by_date_and_court_id( opts[ :date], opts[ :court])
    opts[ :date] += 1
  end
  opts[ :text] ||= "Fri text"
  if count == 1
    create_test_court_day_note_do opts, do_not_save
  else
    count.times.collect{ create_test_court_day_note_do opts, do_not_save, :ic}
  end
end
def create_test_court_day_note_do( attrs, do_not_save, increment = false)
  used = attrs.dup
  used[ :date] = CourtDay.ensure_weekday( used[ :date])
  attrs[ :date] = used[ :date] + rand( 2) + 1 if increment
  if do_not_save
    CourtDayNote.new used
  else
    CourtDayNote.create! used
  end
end
private :create_test_court_day_note_do

def bookings
  [ [ 1, 3], [ 1, 6], [ 2, 5], [ 2, 2], [ 3, 1], [ 3, 3]]
end

def create_test_bookings
  u1, u2, u3 = create_test_user count: 3
  s1, s2, s3, s4, s5, s6 = create_test_court_session count: 6
  6.times{ |i| eval( "s#{ i + 1}").update_attribute :need, i / 2 + 1}
  bookings.each do |u, s|
    Booking.create! user: eval( "u#{ u}"), court_session: eval( "s#{ s}")
  end
end

def diff_to_text( diff, unit, less, more)
  if diff < -1
    "#{ diff.abs} #{ unit}s #{ less}"
  elsif diff == -1
    "1 #{ unit} #{ less}"
  elsif diff == 0
    "at"
  elsif diff == 1
    "1 #{ unit} #{ more}"
  else
    "#{ diff} #{ unit}s #{ more}"
  end
end

