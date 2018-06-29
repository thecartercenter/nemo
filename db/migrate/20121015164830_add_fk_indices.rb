class AddFkIndices < ActiveRecord::Migration[4.2]
  def up
    add_index :answers, :response_id
    add_index :answers, :option_id
    add_index :choices, :option_id
    add_index :forms, :form_type_id
    add_index :questions, :option_set_id
    add_index :questions, :question_type_id
    add_index :responses, :user_id
    add_index :translations, [:fld, :class_name, :obj_id, :language]
  end

  def down
  end
end
