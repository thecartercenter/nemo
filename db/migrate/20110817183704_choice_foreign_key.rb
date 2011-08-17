class ChoiceForeignKey < ActiveRecord::Migration
  def self.up
    add_index(:choices, [:answer_id])
  end

  def self.down
  end
end
