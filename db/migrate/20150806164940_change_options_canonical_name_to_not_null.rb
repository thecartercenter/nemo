class ChangeOptionsCanonicalNameToNotNull < ActiveRecord::Migration
  def change
    [Option, Question].each do |k|
      k.where(canonical_name: nil).each{ |o| o.update_attribute(:canonical_name, o.name) }
    end
    change_column_null :options, :canonical_name, false
  end
end
