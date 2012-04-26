class ConvertBlankAnswerValuesToNulls < ActiveRecord::Migration
  def up
    execute("UPDATE answers SET value = NULL WHERE TRIM(value) = ''")
  end

  def down
  end
end
