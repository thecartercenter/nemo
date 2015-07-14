class AddReviewerNotesToResponse < ActiveRecord::Migration
  def change
    add_column :responses, :reviewer_notes, :text
  end
end
