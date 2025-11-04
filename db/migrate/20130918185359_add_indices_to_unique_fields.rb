class AddIndicesToUniqueFields < ActiveRecord::Migration[4.2]
  def change
    add_index(:forms, %i[mission_id name], unique: true)
    add_index(:option_sets, %i[mission_id name], unique: true)
    add_index(:questions, %i[mission_id code], unique: true)
  end
end
