class ConvertTranslationsToJsonb < ActiveRecord::Migration[4.2]
  def up
    [
      %w(questions name),
      %w(questions hint),
      %w(form_items group_name),
      %w(form_items group_hint),
      %w(options name)
    ].each do |col|
      table = col.first
      col_name = "#{col.last}_translations"
      execute("ALTER TABLE #{table} ADD COLUMN #{col_name}_jsonb jsonb DEFAULT '{}'")
      execute("UPDATE #{table} set #{col_name}_jsonb = #{col_name}::jsonb")
      execute("ALTER TABLE #{table} DROP COLUMN #{col_name}")
      execute("ALTER TABLE #{table} RENAME COLUMN #{col_name}_jsonb TO #{col_name}")
    end
  end
end
