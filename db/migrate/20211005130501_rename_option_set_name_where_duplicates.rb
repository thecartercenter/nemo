class RenameOptionSetNameWhereDuplicates < ActiveRecord::Migration[6.1]
  def up
    # for each mission
    OptionSet.find_each do |os|
      sets = OptionSet.where(mission_id: os.mission_id).where(name: os.name)
      next if sets.count < 2
      sets.each do |set|
        set.name = "#{set.name} #{set.created_at}"
        set.save
      end
    end

    add_index(:option_sets, %i[name mission_id], unique: true)
  end
end
