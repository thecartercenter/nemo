class Setting < ActiveRecord::Base
end

class PopulateOverrideCodes < ActiveRecord::Migration[4.2]
  def up
    Setting.where('mission_id IS NOT NULL').each do |s|
      s.override_code = Random.alphanum_no_zero(6)
      s.save(:validate => false)
    end
  end

  def down
  end
end
