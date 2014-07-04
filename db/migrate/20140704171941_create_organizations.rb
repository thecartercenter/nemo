class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :compact_name

      t.timestamps
    end
    add_column :missions, :organization_id, :integer
  end
end
