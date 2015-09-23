class CreateSnapshot < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.text :all_data
      t.timestamps
    end
  end
end
