# frozen_string_literal: true

# Adds rank column to conditions table and initializes the values.
class AddRankToConditions < ActiveRecord::Migration[4.2]
  def up
    add_column :conditions, :rank, :integer
    FormItem.find_each { |form_item| update_ranks(form_item.display_conditions) }
    SkipRule.find_each { |skip_rule| update_ranks(skip_rule.conditions) }

    # These need a rank due to null constraint but it doesn't matter what it is.
    execute("UPDATE conditions SET rank = 1 WHERE deleted_at IS NOT NULL")

    change_column_null :conditions, :rank, false
  end

  def down
    remove_column :conditions, :rank
  end

  private

  def update_ranks(scope)
    scope.each.with_index(1) { |c, i| c.update_column(:rank, i) }
  end
end
