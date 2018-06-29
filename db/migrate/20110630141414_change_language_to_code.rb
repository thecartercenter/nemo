class ChangeLanguageToCode < ActiveRecord::Migration[4.2]
  def self.up
    remove_column(:languages, :name)
    add_column(:languages, :code, :string)
  end

  def self.down
    add_column(:languages, :name, :string)
    remove_column(:languages, :code)
  end
end
