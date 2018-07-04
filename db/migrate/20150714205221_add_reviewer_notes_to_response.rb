class AddReviewerNotesToResponse < ActiveRecord::Migration[4.2]
  def change
    add_column :responses, :reviewer_notes, :text
  end
end
