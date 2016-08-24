class AddDemographicFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :gender, :string
    add_column :users, :gender_custom, :string
    add_column :users, :birth_year, :integer
    add_column :users, :nationality, :string
    add_column :users, :experience, :text
  end
end
