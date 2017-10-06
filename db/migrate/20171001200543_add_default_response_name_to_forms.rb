class AddDefaultResponseNameToForms < ActiveRecord::Migration
  def change
    add_column :forms, :default_response_name, :string
  end
end
