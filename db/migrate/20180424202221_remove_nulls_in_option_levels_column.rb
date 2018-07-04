# frozen_string_literal: true

# Somehow these snuck in but I think whatever let them in has been fixed.
class RemoveNullsInOptionLevelsColumn < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE option_sets SET level_names = NULL where level_names = 'null'")
  end
end
