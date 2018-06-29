class AddDefaultResponseNameToForms < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :default_response_name, :string
  end
end
