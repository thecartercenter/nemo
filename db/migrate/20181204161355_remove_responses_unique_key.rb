# frozen_string_literal: true

# Don't really need this anymore it seems. It's quite old and not clear what purpose it is serving.
# It doesn't do much to guard the integrity of ranks because it only checks for duplicates,
# not sequentiality.
class RemoveResponsesUniqueKey < ActiveRecord::Migration[5.1]
  def up
    remove_index(:answers, name: :answers_full)
  end
end
