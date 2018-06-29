class ChangeUserToOneNameField < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :name, :string
    User.all.each{|u| u.name = "#{u.first_name} #{u.last_name}"; u.save(:validate => false)}
    remove_column :users, :first_name
    remove_column :users, :last_name
  end

  def self.down
    remove_column :users, :name
  end
end
