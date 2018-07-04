class AddNullifyToOriginalIdFks < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key "forms", column: "original_id", name: "forms_standard_id_fk" rescue 'No fk to remove...'
    add_foreign_key "forms", "forms", column: "original_id", name: "forms_standard_id_fk", on_delete: :nullify

    remove_foreign_key "option_sets", column: "original_id", name: "option_sets_standard_id_fk" rescue 'No fk to remove...'
    add_foreign_key "option_sets", "option_sets", column: "original_id", name: "option_sets_standard_id_fk", on_delete: :nullify

    remove_foreign_key "questions", column: "original_id", name: "questions_standard_id_fk" rescue 'No fk to remove...'
    add_foreign_key "questions", "questions", column: "original_id", name: "questions_standard_id_fk", on_delete: :nullify
  end

  def down
    remove_foreign_key "forms", column: "original_id", name: "forms_standard_id_fk"
    remove_foreign_key "option_sets", column: "original_id", name: "option_sets_standard_id_fk"
    remove_foreign_key "questions", column: "original_id", name: "questions_standard_id_fk"
  end
end
