class FixCurrentVersionForeignKeyConstraint < ActiveRecord::Migration
  def up
    # this should have been a nullify constraint
    remove_foreign_key(:forms, :name => 'forms_current_version_id_fk')
    add_foreign_key(:forms, :form_versions, :column => "current_version_id", :dependent => :nullify)
  end

  def down
  end
end
