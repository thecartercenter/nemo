class Setting < ActiveRecord::Base
end

class PopulateOverrideCodes < ActiveRecord::Migration
  def up
    Setting.where('mission_id IS NOT NULL').each do |s|
      s.override_code = ('a'..'z').to_a.shuffle[0,6].join
      s.save(:validate => false)
    end
  end

  def down
  end
end
