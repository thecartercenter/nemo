class AddForeignKeyIndices < ActiveRecord::Migration
  def change
    add_index(:responses, :form_id)
    add_index(:questionings, :form_id)
    add_index(:questionings, :question_id)
  end
end
