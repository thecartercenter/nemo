# frozen_string_literal: true

# ActiveRecord and sql queries need to filter on type
class AddTypeIndexToAnswers < ActiveRecord::Migration
  def change
    add_index :answers, :type
  end
end
