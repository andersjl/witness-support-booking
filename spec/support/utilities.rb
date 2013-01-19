
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

def sign_in( user)
  visit signin_path
  fill_in "E-post", :with => user.email
  fill_in "Lösenord", :with => user.password
  click_button "Logga in"
  cookies[ :remember_token] = user.remember_token  # if not Capybara
end

