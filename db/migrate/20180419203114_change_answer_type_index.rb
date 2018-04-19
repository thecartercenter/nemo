# frozen_string_literal: true

class ChangeAnswerTypeIndex < ActiveRecord::Migration
  def change
    remove_index :answers, :type
    remove_index :answers, :deleted_at

    # deleted_at is checked on pretty much every query.
    # type will also be checked a lot as a filter.
    # So it makes more sense to have these as a composite index.
    add_index :answers, %i[deleted_at type]
  end
end
