class CreateCourtSessionsAndCourtDayNotesDropCourtDays <
        ActiveRecord::Migration

# define a phony set of models and associations to make the migration
# independent of the version of the model code.  The phony set includes
# CourtDay AS WELL AS CourtSession and CourtDayNote.

  class Court < ActiveRecord::Base
    has_many :users
    has_many :court_days
    has_many :court_sessions
    has_many :court_day_notes
  end

  class User < ActiveRecord::Base
    belongs_to :court
    has_many :bookings
  end

  class CourtDay < ActiveRecord::Base
    attr_accessible :court, :date, :morning, :afternoon, :notes
    belongs_to :court
    # the following is to simplify rollback, booking mapping is not one-to-one
    has_many :bookings, dependent: :destroy
  end

  class CourtSession < ActiveRecord::Base
    attr_accessible :court, :date, :start, :need
    belongs_to :court
    has_many :bookings
  end

  class CourtDayNote < ActiveRecord::Base
    attr_accessible :court, :date, :text
    belongs_to :court
  end

  # A major difference to the "down" Booking model is that we do not typecast
  class Booking < ActiveRecord::Base
    attr_accessible :user, :court_day, :court_session, :session
    belongs_to :user
    belongs_to :court_day
    belongs_to :court_session
  end

  def up

    create_table :court_sessions do |t|
      t.integer :court_id, null: false
      t.date    :date,     null: false
      t.integer :start,    null: false
      t.integer :need,     null: false
      t.timestamps
    end
    add_index :court_sessions, [ :date, :court_id, :start], unique: true
    add_index :court_sessions, :court_id

    create_table :court_day_notes do |t|
      t.integer :court_id, null: false
      t.date    :date,     null: false
      t.text    :text,     null: false
      t.timestamps
    end
    add_index :court_day_notes, [ :date, :court_id], unique: true
    add_index :court_day_notes, :court_id

    # Index removed here because temporary index name becomes too long, at
    # least using sqlite3.
    remove_index :bookings, [ :court_day_id, :user_id, :session]
    change_column :bookings, :court_day_id, :integer, null: true
    change_column :bookings, :session, :integer, null: true
    add_column :bookings, :court_session_id, :integer
    add_index :bookings, [ :court_session_id, :user_id], unique: true
    Booking.reset_column_information

    CourtDay.all.each do |court_day|
      court = court_day.court
      date = court_day.date
      [ :morning, :afternoon].each do |session|
        old_bookings = court_day.bookings.where(
                         "session = ?", session_to_int( session)).to_a
        need = court_day.send( session)
        next if old_bookings.count == 0 && need == 0
        court_session = CourtSession.create! court: court, date: date,
                          start: session_to_start( session), need: need
        old_bookings.each do |old_booking|
          new_booking = Booking.create! user: old_booking.user,
                                        court_session: court_session
          old_booking.delete
        end
      end
      unless court_day.notes.blank?
        CourtDayNote.create! court: court, date: date, text: court_day.notes
      end
    end

    change_column :bookings, :court_session_id, :integer, null: false
    # Also removes the erronous index on court_day_id, if present.
    remove_column :bookings, :court_day_id
    remove_column :bookings, :session
    Booking.reset_column_information

    drop_table :court_days
  end

  def down

    change_column :bookings, :court_session_id, :integer, null: true
    add_column :bookings, :court_day_id, :integer
    add_column :bookings, :session, :integer
    Booking.reset_column_information

    create_table "court_days" do |t|
     t.integer  :court_id,  null: false
      t.date    :date,      null: false
      t.integer :morning,   null: false
      t.integer :afternoon, null: false
      t.text :notes
      t.timestamps
    end
    add_index :court_days, [ :court_id, :date], unique: true
    add_index :court_days, :date

    CourtSession.all.each do |court_session|
      need = court_session.need
      session = start_to_session( court_session.start)
      old_bookings = court_session.bookings.to_a
      court_day = find_court_day court_session.court, court_session.date
      court_day.update_attributes session => need
      old_bookings.each do |old_booking|
        Booking.create! user: old_booking.user, court_day: court_day,
                        session: session_to_int( session)
        old_booking.delete
      end
    end
    CourtDayNote.all.each do |court_day_note|
      court_day = find_court_day court_day_note.court, court_day_note.date
      court_day.update_attributes :notes => court_day_note.text
    end
    # the above may have created court_days that are invalid because of the
    # custom validation there_must_be_something_to_do
    CourtDay.all.each do |cd|
      cd.destroy if cd.morning == 0 && cd.afternoon == 0 && cd.notes.blank?
    end

    change_column :bookings, :court_day_id, :integer, null: false
    change_column :bookings, :session,      :integer, null: false
    remove_index :bookings, [ :court_session_id, :user_id]
    remove_column :bookings, :court_session_id
    # Index created here because temporary index name becomes too long, and we
    # do not bother setting index name - the migration runs only once.
    add_index :bookings, [ :court_day_id, :user_id, :session], unique: true
    # In version 20130206085228 court_day_id was given a single column index.
    # This is a bug that we do not recreate.  However, this will crash further
    # rollback unless it is removed from version 20130206085228 as well.
    Booking.reset_column_information

    drop_table :court_day_notes
    drop_table :court_sessions
  end
  
  def find_court_day( court, date)
    result = CourtDay.find_by_court_id_and_date court.id, date
    result = CourtDay.new( court: court, date: date, morning: 0, afternoon: 0
                         ) unless result
    result
  end

  START_TIME_OF_DAY = { morning:    (8 * 60 + 15) * 60,
                        afternoon: (12 * 60 + 15) * 60}

  def session_to_start( session); START_TIME_OF_DAY[ session] || 0 end

  def start_to_session( start)
    START_TIME_OF_DAY.each_pair{ |ses, tod| return ses if tod == start}
    :unknown
  end

  def session_to_int( session)
    case session.to_sym
    when :morning   then  0
    when :afternoon then  1
    else                 -1
    end
  end
end

