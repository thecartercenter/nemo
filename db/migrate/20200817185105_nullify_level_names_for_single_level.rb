# frozen_string_literal: true

# Somehow at least one option set got assigned level_names without actually being multilevel.
# Normalize any other instances that may exist.
class NullifyLevelNamesForSingleLevel < ActiveRecord::Migration[5.2]
  def up
    OptionSet.all.each do |option_set|
      next if option_set.multilevel? || option_set.level_names.nil?
      puts "Found invalid option_set #{option_set.id}"
      option_set.update!(level_names: nil)
    end
  end

  def down
    # No worries.
  end
end
