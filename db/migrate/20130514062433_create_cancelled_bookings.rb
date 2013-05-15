class CreateCancelledBookings < ActiveRecord::Migration
  def change
    create_table :cancelled_bookings do |t|
      t.integer :user_id,          null: false
      t.integer :court_session_id, null: false
      t.datetime :cancelled_at, null: false
      t.timestamps
    end
    add_index :cancelled_bookings,
              [ :court_session_id, :user_id], unique: true
  end
end
