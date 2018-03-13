class CancelledBookingNotUnique < ActiveRecord::Migration[5.1]

  def up
    change_table :cancelled_bookings do |t|
      t.remove_index [ :court_session_id, :user_id]
      t.index [ :court_session_id, :user_id]
    end
  end

  def down
    change_table :cancelled_bookings do |t|
      t.remove_index [ :court_session_id, :user_id]
      t.index [ :court_session_id, :user_id], unique: true
    end
  end
end
