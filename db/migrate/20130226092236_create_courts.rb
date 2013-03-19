class CreateCourts < ActiveRecord::Migration

  def up

    create_table :courts do |t|
      t.string :name, :null => false
      t.string :link, :default => "#"

      t.timestamps
    end
    add_index :courts, :name, :unique => true
    court_default = Court.create! :name => "Default"

    change_table :bookings do |t|
      t.remove_index [ :court_day_id, :user_id, :session]
      t.change :user_id, :integer, :null => false
      t.change :court_day_id, :integer, :null => false
      t.change :session, :integer, :null => false
      t.index [ :court_day_id, :user_id, :session], :unique => true
    end

    change_table :court_days do |t|
      t.column :court_id, :integer
      t.remove_index :date
      t.index :date  # no longer unique
      t.index [ :court_id, :date], :unique => true
      CourtDay.reset_column_information
      CourtDay.all.each{ |cd| cd.update_attribute :court_id, court_default.id}
      t.change :date, :date, :null => false
      t.change :morning, :integer, :null => false
      t.change :afternoon, :integer, :null => false
      t.change :court_id, :integer, :null => false
    end

    change_table :users do |t|
      t.column :court_id, :integer
      t.remove_index :email
      t.index :email  # no longer unique
      t.index [ :court_id, :email], :unique => true
      User.reset_column_information
      User.all.each do |u|
        u.update_attribute :court_id, court_default.id
        u.update_attribute( :role, "master") if u.role == "admin"
      end
      t.change :name, :string, :null => false
      t.change :email, :string, :null => false
      t.change :court_id, :integer, :null => false
    end
  end

  def down

    default_court = Court.all.inject( [ nil, -1]){ |c_mx, c|
      c.users.count > c_mx[ 1] ? [ c, c.users.count] : c_mx}.first
    [ User, CourtDay].each{ |model|
      model.all.each{ |obj| obj.destroy unless obj.court == default_court}}
    User.where( "role = ?", "master").
      each{ |u| u.update_attribute :role, "admin"}
    remove_index :users, [ :court_id, :email]
    remove_column :users, :court_id
    remove_index :users, :email
    add_index :users, :email, :unique => true

    remove_index :court_days, [ :court_id, :date]
    remove_column :court_days, :court_id
    remove_index :court_days, :date
    add_index :court_days, :date, :unique => true

    drop_table :courts
  end
end

