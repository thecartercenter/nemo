class AddUserFormCompositeIndexOnResponses < ActiveRecord::Migration[4.2]
  def change
    add_index :responses, [:user_id, :form_id]
  end
end
