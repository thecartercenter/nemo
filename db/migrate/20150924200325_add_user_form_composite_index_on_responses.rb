class AddUserFormCompositeIndexOnResponses < ActiveRecord::Migration
  def change
    add_index :responses, [:user_id, :form_id]
  end
end
