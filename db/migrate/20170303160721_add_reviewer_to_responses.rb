class AddReviewerToResponses < ActiveRecord::Migration[4.2]
  def change
    add_reference :responses, :reviewer, references: :user, index: true
    add_foreign_key :responses, :users, column: :reviewer_id
  end
end
