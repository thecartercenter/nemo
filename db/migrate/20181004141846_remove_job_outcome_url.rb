# frozen_string_literal: true

class RemoveJobOutcomeUrl < ActiveRecord::Migration[5.1]
  def up
    remove_column(:operations, :job_outcome_url)
  end

  def down
    add_column(:operations, :job_outcome_url, :string)
  end
end
