class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :subdomain, null: false

      t.timestamps
    end

    add_column "missions", "organization_id", :integer
    add_column "forms", "organization_id", :integer
    add_column "questionings", "organization_id", :integer
    add_column "questionables", "organization_id", :integer
    add_column "option_sets", "organization_id", :integer
    add_column "options", "organization_id", :integer

    add_foreign_key "missions", "organizations", name: "missions_organizations_id_fk", column: "organization_id"
    add_foreign_key "forms", "organizations", name: "forms_organizations_id_fk", column: "organization_id"
    add_foreign_key "questionings", "organizations", name: "questionings_organizations_id_fk", column: "organization_id"
    add_foreign_key "questionables", "organizations", name: "questionables_organizations_id_fk", column: "organization_id"
    add_foreign_key "option_sets", "organizations", name: "option_sets", column: "organization_id"
    add_foreign_key "options", "organizations", name: "options", column: "organization_id"

    add_index :organizations, [:name, :subdomain], unique: true
  end
end
