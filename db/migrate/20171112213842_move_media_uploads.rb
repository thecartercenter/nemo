class MoveMediaUploads < ActiveRecord::Migration[4.2]
  TABLES = [Media::Object, Media::Image, Media::Audio, Media::Video]

  def up
    TABLES.each { |table| table.reset_column_information }

    Media::Object.find_each do |object|
      class_path = object.type.underscore.pluralize
      old_id_part = ("%09d" % object.old_id).scan(/\d{3}/).join("/")
      new_id_part = object.id.split("-").join("/")

      old_path = Rails.root.join("uploads", class_path, "items", old_id_part).to_s
      new_path = Rails.root.join("uploads", class_path, "items", new_id_part).to_s

      puts "Moving #{old_path} -> #{new_path}"

      FileUtils.mkpath(new_path)
      FileUtils.move(Dir.glob([old_path, "*"].join("/")), new_path)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
