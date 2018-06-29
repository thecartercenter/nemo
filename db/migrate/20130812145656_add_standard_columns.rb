class AddStandardColumns < ActiveRecord::Migration[4.2]
  def up
    %w(forms form_versions questions questionings conditions option_sets options optionings).each do |t|
      t = t.to_sym
      add_column t, :is_standard, :boolean, :default => false
      add_column t, :standard_id, :integer
      add_index t, :standard_id
    end
  end

  def down
  end
end
