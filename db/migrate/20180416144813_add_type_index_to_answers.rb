# frozen_string_literal: true

# ActiveRecord and sql queries need to filter on type
class AddTypeIndexToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_index :answers, :type
  end
end
