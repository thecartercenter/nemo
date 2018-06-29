class AddSourceToResponse < ActiveRecord::Migration[4.2]
  def self.up
    add_column :responses, :source, :string
    execute("update responses set source='odk'")
  end

  def self.down
    remove_column :responses, :source
  end
end
