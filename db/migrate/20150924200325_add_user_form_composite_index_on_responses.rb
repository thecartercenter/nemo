class AddUserFormCompositeIndexOnResponses < ActiveRecord::Migration[4.2]
  def change
    add_index :responses, %i[user_id form_id]
  end
end
