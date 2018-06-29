class MoveUsersToDefaultMission < ActiveRecord::Migration[4.2]
  def up
    transaction do
      # get default mission
      dm = Mission.find_by_name("Default")

      # add users, copying the requisite fields
      User.all.each do |u|
        u.assignments.create!(:mission_id => dm.id, :role_id => u.role_id, :active => u.active?)
      end
    end
  end

  def down
  end
end
