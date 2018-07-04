class ChangeQuestionsCanonicalNameToNotNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :questions, :canonical_name, false
  end
end
