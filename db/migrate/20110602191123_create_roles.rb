class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name
      t.integer :level
      t.boolean :location_required

      t.timestamps
    end
    Role.create(:name => "Observer", :level => 1)
    Role.create(:name => "Coordinator", :level => 2)
    Role.create(:name => "Director", :level => 3)
    Role.create(:name => "Program Staff", :level => 4)
  end

  def self.down
    drop_table :roles
  end
end
