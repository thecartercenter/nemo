class AddForeignKeyIndices < ActiveRecord::Migration[4.2]
  def change
    # if the indices already exist, that's ok
    begin
      add_index(:responses, :form_id)
    rescue StandardError
      nil
    end
    begin
      add_index(:questionings, :form_id)
    rescue StandardError
      nil
    end
    begin
      add_index(:questionings, :question_id)
    rescue StandardError
      nil
    end
  end
end
