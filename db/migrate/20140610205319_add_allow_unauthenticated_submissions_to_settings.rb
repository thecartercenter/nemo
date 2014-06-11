class AddAllowUnauthenticatedSubmissionsToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :allow_unauthenticated_submissions, :boolean, :default => false
  end
end
