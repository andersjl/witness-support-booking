class CreateCourtDays < ActiveRecord::Migration
  def change
    create_table :court_days do |t|
      t.date :date
      t.integer :morning
      t.integer :afternoon
      t.text :notes

      t.timestamps
    end
    add_index :court_days, :date, :unique => true
  end
end
