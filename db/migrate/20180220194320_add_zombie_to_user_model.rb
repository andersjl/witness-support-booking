class AddZombieToUserModel < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :zombie, :boolean, default: false
  end
end

