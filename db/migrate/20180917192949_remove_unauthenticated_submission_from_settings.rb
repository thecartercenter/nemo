# frozen_string_literal: true

class RemoveUnauthenticatedSubmissionFromSettings < ActiveRecord::Migration[5.1]
  def change
    remove_column(:settings, :allow_unauthenticated_submissions, :boolean, default: false, null: false)
  end
end
