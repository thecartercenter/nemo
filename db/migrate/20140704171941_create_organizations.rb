class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :subdomain, null: false

      t.timestamps
    end
    add_column :missions, :organization_id, :integer
    add_column :forms, :organization_id, :integer  
    add_foreign_key "missions", "organizations", name: "missions_organizations_id_fk", column: "organization_id"
    add_foreign_key "forms", "organizations", name: "forms_organizations_id_fk", column: "organization_id"
    add_index :organizations, [:name, :subdomain], unique: true
  end
end
