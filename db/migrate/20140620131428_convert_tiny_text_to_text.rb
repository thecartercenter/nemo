class ConvertTinyTextToText < ActiveRecord::Migration
  def up
    execute("UPDATE questionables SET qtype_name = 'text' WHERE qtype_name = 'tiny_text'")
  end

  def down
  end
end
