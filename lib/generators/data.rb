# encoding: UTF-8

module Generators
module Data

  def generate_court_days( start_date, no_weekdays, *courts)
    first_monday = CourtDay.monday( start_date)
    start_day = start_date - first_monday
    [ courts].flatten.each do |court|
      sessions = 0
      notes = 0
      long_text = rand( no_weekdays)
      no_weekdays.times do |d|
        weeks, days = (start_day + d).divmod( 5)
        date = first_monday + 7 * weeks + days
        [ 0, 1].each do |start_ix|
          need = rand( 4)
          need += rand( PARALLEL_SESSIONS_MAX - 2) if need == 3
          if need > 0
            CourtSession.create(
              court: court,
              date:  date,
              start: START_TIMES_OF_DAY_DEFAULT[ start_ix],
              need:  need)
            sessions += 1
          end
        end
        if d == long_text
          note = %Q$En lång text med en radbrytning här ->\r\noch så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare och så vidare$ 
        elsif rand( 3) > 0
          note = "Fri text nummer #{ d + 1}"
        end
        unless note.blank?
          CourtDayNote.create( court: court, date: date, text: note)
          notes += 1
        end
      end
      yield court, sessions, notes if block_given?
    end
  end

  def generate_bookings( *courts)
    [ courts].flatten.each do |court|
      bookings  = 0
      unbooked  = 0
      cancelled = 0
      users = User.where( [ "court_id = ? and role = ?", court.id, "normal"])
      shortlist = users[ 0, 3].compact
      CourtSession.where( [ "court_id = ?", court]).each do |session|
        bookings_before = bookings
        session.need.times do
          user = (rand( 3) == 0 ? shortlist : users).sample
          case rand( 6)
          when 0
            CancelledBooking.create( user: user, court_session: session,
              cancelled_at:
                [ session.date.midnight + session.start, Time.current
                ].min -
                  rand( ( 0 == rand( 2) ?
                      BOOKING_DAYS_AHEAD_MIN : BOOKING_DAYS_AHEAD_MAX
                    ) * 86400
            )     )
            cancelled += 1
          when 1
            #  do nothing
          else
            if ! user.booked?( session)
              Booking.create( user: user, court_session: session,
                booked_at: session.date - rand( 10)
              )
              bookings += 1
            end
          end
        end
        unbooked += 1 if bookings == bookings_before
      end
      yield court, bookings, unbooked, cancelled if block_given?
    end
  end

end
end

