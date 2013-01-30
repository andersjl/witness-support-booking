
def create_test_user( opts = { })
  count = opts.delete( :count) || 1
  if count == 1
    create_test_user_do opts
  else
    count.times.collect{ |no| create_test_user_do opts, (no + 1).to_s}
  end
end
def create_test_user_do( attrs, extra = nil)
  em = attrs[ :email] || "ex@empel.se"
  nm = attrs[ :name] || "Ex Empel"
  if extra
    em = extra.to_s + em
    nm += extra.to_s
    admin = false
  else
    admin = attrs[ :admin]
  end
# puts "User.create :email => #{ em}, :name => #{ nm}, :password => \"dåligt\", :password_confirmation => \"dåligt\""
  result = User.create! :email => em, :name => nm, :password => "dåligt",
                        :password_confirmation => "dåligt"
  result.toggle! :admin if admin
# puts result.inspect
  result
end
private :create_test_user_do

def log_in( user)
  visit log_in_path
  fill_in "E-post", :with => user.email
  fill_in "Lösenord", :with => user.password
  click_button "Logga in"
  cookies[ :remember_token] = user.remember_token  # if not Capybara
end

def create_test_court_day( opts = { })
  opts = opts.dup
  count = opts.delete( :count) || 1
  do_not_save = opts.delete :do_not_save
  opts[ :date] ||= Date.today
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
  attrs[ :date] += rand( 2) + 1 if increment
  attrs = attrs.dup
  if increment
    attrs[ :morning] = rand( attrs[ :morning] + 1)
    attrs[ :afternoon] = rand( attrs[ :afternoon] + 1)
    attrs.delete( :notes) if
      (attrs[ :morning] > 0 || attrs[ :afternoon] > 0) && rand( 2) == 0
  end
  if do_not_save
    CourtDay.new attrs
  else
    CourtDay.create! attrs
  end
end
private :create_test_court_day_do

def expand_if_proc( possibly_proc, arg)
  possibly_proc.is_a?( Proc) ? possibly_proc.call( arg) : possibly_proc
end

=begin
def create_test_court_day_randomize( attrs, key)
  n = rand( attrs[ key] + 1)
  if n == 0
    attrs.delete key
  else
    attrs[ key] = n
  end
end
private :create_test_court_day_randomize
=end

=begin
def create_test_booking( opts = { })
  count = opts.delete( :count) || 1
  if count == 1
    create_test_booking_do opts
  else
    count.times.collect{ |no| create_test_booking_do opts, no + 1}
  end
end
def create_test_booking_do( attrs, extra = nil)
  attrs = attrs.dup
  attrs[ :court_day] ||= Date.today
  attrs[ :afternoon] ||= false
  user = attrs.delete( :user)
  if extra
    add_to_court_days, afternoon = extra.divmod 2
    attrs[ :court_day] += add_to_court_days
    attrs[ :afternoon] = (afternoon == 1)
  end
# result =
  if user
    user.bookings.create! attrs
  else
  # puts attrs.inspect
    Booking.create! attrs
  end
# puts result.inspect
# result
end
private :create_test_booking_do
=end

