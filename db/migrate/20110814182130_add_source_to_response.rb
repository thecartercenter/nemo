class AddSourceToResponse < ActiveRecord::Migration
  def self.up
    add_column :responses, :source, :string
    execute("update responses set source='odk'")
  end

  def self.down
    remove_column :responses, :source
  end
end
