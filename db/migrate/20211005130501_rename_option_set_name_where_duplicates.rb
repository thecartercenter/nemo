# frozen_string_literal: true

class RenameOptionSetNameWhereDuplicates < ActiveRecord::Migration[6.1]
  def up
    OptionSet.find_each do |os|
      sets = OptionSet.where(mission_id: os.mission_id, name: os.name)
      next if sets.count < 2
      sets.each do |set|
        puts "Renaming duplicate option set ##{set.id}: #{set.name}"
        set.update!(name: "#{set.name} #{set.created_at}")
      end
    end

    add_index(:option_sets, %i[name mission_id], unique: true)
  end

  def down
    remove_index(:option_sets, %i[name mission_id])
  end
end
