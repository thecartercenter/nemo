class ConvertTinyTextToText < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE questionables SET qtype_name = 'text' WHERE qtype_name = 'tiny_text'")
  end

  def down
  end
end
