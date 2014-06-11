class AddAllowUnauthenticatedSubmissionsToMissions < ActiveRecord::Migration
  def change
    add_column :missions, :allow_unauthenticated_submissions, :boolean, :default => false
  end
end
