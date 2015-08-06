class ChangeOptionsCanonicalNameToNotNull < ActiveRecord::Migration
  def change
    change_column_null :options, :canonical_name, false
  end
end
