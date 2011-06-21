class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages do |t|
      t.string :name
      t.boolean :is_active
      
      t.timestamps
    end
    Language.create(:name => "English")
    Language.create(:name => "French")
  end

  def self.down
    drop_table :languages
  end
end
