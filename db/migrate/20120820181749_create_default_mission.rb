class CreateDefaultMission < ActiveRecord::Migration
  def up
    Mission.create(:name => "Default")
  end

  def down
  end
end
