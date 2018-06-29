class RemoveOldTranslationsTable < ActiveRecord::Migration[4.2]
  def up
    # Now obsolete
    #
    # # copy all translations to appropriate models
    # puts "Copying translations from old table"
    # tx = ActiveRecord::Base.connection.select("SELECT * FROM translations")
    # tx.each do |row|
    #   # try to get object
    #   obj = row['class_name'].constantize.find_by_id(row['obj_id'])
    #   if obj
    #     # assign appropriate field and save
    #     obj.send("#{row['fld']}_#{row['language']}=", row['str'])
    #     obj.save(:validate => false)
    #
    #   # print message if not found
    #   else
    #     puts "#{row['class_name']} #{row['obj_id']} not found."
    #   end
    # end
    #
    # # set default values for any fields without translations
    # puts "Checking for missing translations"
    # [Question, Option].each do |klass|
    #   klass.where(:_name => nil).all.each do |obj|
    #     puts "Assigning default name for #{klass} #{obj.id}"
    #     obj.name = "Default name"
    #     obj.save(:validate => false)
    #   end
    # end
    #
    drop_table :translations
  end

  def down
  end
end
