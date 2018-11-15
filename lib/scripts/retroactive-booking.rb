# Save under another name, enter your data, save, and type
#   cat <script file name> |rails console
#
# choose your court name!
court_id = Court.where( name: 'some court').first.id
# choose your witness support names!
ws1_id = User.where( name: 'some wittness support').first.id
ws2_id = User.where( name: 'some other').first.id
# choose your start times!
t1 = ( 8 * 60 + 15) * 60
t2 = ( 12 * 60 + 15) * 60
[   [ '2018-02-13', [ ws1_id, ws2_id], [ ws1_id]],
    # more rows
].each do | date, t1_users, t2_users|
    [   [ t1, *t1_users], [ t2, *t2_users]].each do | start, *users|
        cs = CourtSession.where( court_id: court_id, date: date, start: start)
        if 0 < cs.count
            cs = cs.first
        else
            cs = CourtSession.create!(
                    court_id: court_id, date: date, start: start, need: 1
                )
            cs.update_attribute( :need, 0);
        end
        users.each do | u|
            cs.update_attribute( :need, cs.need + 1)
            bk = Booking.create!(
                    user_id: u, court_session_id: cs.id, booked_at: Date.today
                )
        end
    end
end

