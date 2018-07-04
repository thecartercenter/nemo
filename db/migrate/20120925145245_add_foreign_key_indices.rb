class AddForeignKeyIndices < ActiveRecord::Migration[4.2]
  def change
    # if the indices already exist, that's ok
    add_index(:responses, :form_id) rescue nil
    add_index(:questionings, :form_id) rescue nil
    add_index(:questionings, :question_id) rescue nil
  end
end
