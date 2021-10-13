# frozen_string_literal: true

class RenameOptionSetNameWhereDuplicates < ActiveRecord::Migration[6.1]
  def up
    OptionSet.find_each do |os|
      sets = OptionSet.where(mission_id: os.mission_id, name: os.name)
      next if sets.count < 2
      sets.each do |set|
        puts "Renaming duplicate option set ##{set.id}: #{set.name}"
        next if set.update(name: "#{set.name} #{set.created_at.to_s(:std_datetime)}")
        # Some may have been created at the same second, e.g. if imported or created from the terminal;
        # if so, append a random string also.
        set.update!(name: "#{set.name} #{SecureRandom.alphanumeric(4)}")
      end
    end

    add_index(:option_sets, %i[name mission_id], unique: true)
  end

  def down
    remove_index(:option_sets, %i[name mission_id])
  end
end
