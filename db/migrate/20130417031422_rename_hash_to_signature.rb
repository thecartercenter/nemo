class RenameHashToSignature < ActiveRecord::Migration
  def up
    rename_column :responses, :hash, :signature
  end

  def down
  end
end
