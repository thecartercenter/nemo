class RemoveOldCols < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key_if_exists(:conditions, :original_id)
    remove_foreign_key_if_exists(:form_items, :original_id)
    remove_foreign_key_if_exists(:options, :original_id)
    remove_foreign_key_if_exists(:taggings, :original_id)
    remove_foreign_key_if_exists(:tags, :original_id)

    remove_column_if_exists(:broadcasts, :recipient_query)
    remove_column_if_exists(:conditions, :original_id)
    remove_column_if_exists(:form_items, :group_rank)
    remove_column_if_exists(:form_items, :original_id)
    remove_column_if_exists(:options, :original_id)
    remove_column_if_exists(:taggings, :original_id)
    remove_column_if_exists(:tags, :original_id)

    change_column_null(:user_group_assignments, :user_group_id, false)
    change_column_null(:user_group_assignments, :user_id, false)
    change_column_null(:user_groups, :name, false)
  end

  def remove_foreign_key_if_exists(table, column)
    if fk = foreign_keys(table).detect { |k| k.options[:column] == column.to_s }
      remove_foreign_key(table, column: column)
    end
  end

  def remove_column_if_exists(*args)
    if column_exists?(*args)
      remove_column(*args)
    end
  end
end
