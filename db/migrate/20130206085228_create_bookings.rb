class CreateBookings < ActiveRecord::Migration
  def change
    create_table :bookings do |t|
      t.integer :user_id
      t.integer :court_day_id
      t.integer :session  # 0 -> am, 1 -> pm

      t.timestamps
    end
  # The following index is a bug.  It was removed in migration 20130407080044.
  # If we do not remove it here, we cannot rollback from 20130407080044. 
  # add_index :bookings, :court_day_id
    add_index :bookings, :user_id
    add_index :bookings, [ :court_day_id, :user_id, :session],
              :unique => true
  end
end
