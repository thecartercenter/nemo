class AddReviewerToResponses < ActiveRecord::Migration
  def change
    add_reference :responses, :reviewer, references: :user, index: true
    add_foreign_key :responses, :users, column: :reviewer_id
  end
end
