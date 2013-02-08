class CreateBookings < ActiveRecord::Migration
  def change
    create_table :bookings do |t|
      t.integer :user_id
      t.integer :court_day_id
      t.integer :session  # 0 -> am, 1 -> pm

      t.timestamps
    end
    add_index :bookings, :court_day_id
    add_index :bookings, :user_id
    add_index :bookings, [ :court_day_id, :user_id, :session],
              :unique => true
  end
end
