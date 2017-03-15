class Mission < ActiveRecord::Base
end

class GenerateShortcodesForMissions < ActiveRecord::Migration
  def up
    charset = ("a".."z").to_a + ("0".."9").to_a

    Mission.find_each do |mission|
      sc = 2.times.map { charset.sample }.join
      mission.update_attributes(shortcode: sc)
    end
  end

  def down
    Mission.update_all(shortcode: nil)
  end
end
