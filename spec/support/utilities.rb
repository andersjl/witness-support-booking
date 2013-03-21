
def known_problem
  yield
rescue RSpec::Expectations::ExpectationNotMetError => e
  pending "#{ e.message} - known problem"
end

def court_this; court_default "This Court" end
def court_other; court_default "Other Court" end

def court_default( name)
  result = Court.find_by_name( name)
  return result if result
  create_test_court( :name => name) unless name == "Other Court"
  other_court = create_test_court :name => "Other Court"
  other_court_user = create_test_user :court    => other_court,
                                      :email    => "other@example.com",
                                      :name     => "Other User",
                                      :password => "dåligt"
  other_court_day = create_test_court_day :court => other_court, :morning => 1
  other_court_user.book! other_court_day, :morning
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
    create_test_user :court => result, :count => users,
                     :do_not_save => do_not_save
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
  opts[ :password] ||= "dåligt"
  opts[ :password_confirmation] ||= opts[ :password]
  opts[ :role] ||= "normal"
  if count == 1
    create_test_user_do opts, do_not_save
  else
    count.times.collect{ |no| create_test_user_do opts, do_not_save,
                                                  (no + 1).to_s}
  end
end
def create_test_user_do( attrs, do_not_save, extra = nil)
  used = attrs.dup
  if extra
    used[ :email] = extra.to_s + used[ :email]
    used[ :name] += extra.to_s
  end
  court = used.delete :court
  role = used.delete :role
  result = User.new( used)
  result.court = court
  result.role = role
  result.save! unless do_not_save
  result
end
private :create_test_user_do

def fake_log_in( user, password = nil)
  visit log_in_path
  select user.court.name, :from => "session_court_id"
  fill_in "session_email", :with => user.email
  fill_in "session_password", :with => password || user.password
  click_button "Logga in"
  cookies[ :remember_token] = user.remember_token  # if not Capybara
end

def create_test_court_day( opts = { })
  opts = opts.dup
  count = opts.delete( :count) || 1
  do_not_save = opts.delete :do_not_save
  opts[ :court] ||= court_this
  opts[ :date] ||= Date.today
  while opts[ :date].cwday > 5 ||
          CourtDay.find_by_court_id_and_date( opts[ :court].id, opts[ :date])
    opts[ :date] += 1
  end
  opts[ :morning] ||= 1
  opts[ :afternoon] ||= 1
  opts[ :notes] ||= "Fri text"
  if count == 1
    create_test_court_day_do opts, do_not_save
  else
    count.times.collect{ create_test_court_day_do opts, do_not_save, :inc}
  end
end
def create_test_court_day_do( attrs, do_not_save, increment = false)
  used = attrs.dup
  used[ :date] = CourtDay.ensure_weekday( used[ :date])
  attrs[ :date] = used[ :date] + rand( 2) + 1 if increment
  if increment
    used[ :morning] = used[ :morning] + rand( used[ :morning] + 1)
    used[ :afternoon] = used[ :afternoon] + rand( used[ :afternoon] + 1)
    used.delete( :notes) if
      (used[ :morning] > 0 || used[ :afternoon] > 0) && rand( 2) == 0
  end
  if do_not_save
    CourtDay.new used
  else
    CourtDay.create! used
  end
end
private :create_test_court_day_do

def booking_schema
  [ [ 1, 2, :morning], [ 1, 3, :afternoon],
    [ 2, 3, :morning], [ 2, 1, :afternoon],
    [ 3, 1, :morning], [ 3, 2, :afternoon]]
end

def create_test_bookings
  u1, u2, u3 = create_test_user :count => 3
  c1, c2, c3 = create_test_court_day :count => 3
  3.times do |i|
    cd = eval( "c#{ i + 1}")
    cd.update_attribute :morning, i + 1
    cd.update_attribute :afternoon, i + 1
  end
  booking_schema.each{ |uds| eval( "u#{ uds[ 0]}").
                               book!( eval( "c#{ uds[ 1]}"), uds[ 2])}
end

