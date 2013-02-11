class AddRoleAndDropAdminAndEnabledFromUsers < ActiveRecord::Migration

  def up
    add_column :users, :role, :string, :default => "disabled"
    User.reset_column_information
    User.all.each do |user|
      user.update_attribute :role, user.admin? ? "admin" : "normal"
    end
    remove_column :users, :admin
    remove_column :users, :enabled
  end


  def down
    add_column :users, :enabled, :boolean
    add_column :users, :admin, :boolean
    User.reset_column_information
    User.all.each do |user|
      user.update_attribute :admin, user.role == "admin"
    end
    remove_column :users, :role
  end
end
