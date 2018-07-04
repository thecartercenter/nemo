class ConvertBlankAnswerValuesToNulls < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE answers SET value = NULL WHERE TRIM(value) = ''")
  end

  def down
  end
end
