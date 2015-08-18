class ChangeQuestionsCanonicalNameToNotNull < ActiveRecord::Migration
  def change
    change_column_null :questions, :canonical_name, false
  end
end
