class AddAllowUnauthenticatedSubmissionsToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :settings, :allow_unauthenticated_submissions, :boolean, :default => false
  end
end
