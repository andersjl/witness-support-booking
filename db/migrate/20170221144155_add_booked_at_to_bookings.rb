class AddBookedAtToBookings < ActiveRecord::Migration

  def up
    add_column :bookings, :booked_at, :date
    Booking.reset_column_information
    Booking.all.each do |booking|
      # at latest they must have been booked the same morning
      booking.update_attribute :booked_at, booking.court_session.date
    end
    change_column_null :bookings, :booked_at, false
  end

  def down
    remove_column :bookings, :booked_at
  end
end
