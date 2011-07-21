class Translation < ActiveRecord::Base
  def self.lookup(class_name, id, field, language)
    language ||= Language.english
    t = find_by_class_name_and_obj_id_and_fld_and_language_id(class_name, id, field, language.id)
    t ? t.str : nil
  end
end
