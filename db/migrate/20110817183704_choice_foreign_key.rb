class ChoiceForeignKey < ActiveRecord::Migration[4.2]
  def self.up
    add_index(:choices, [:answer_id])
  end

  def self.down
  end
end
