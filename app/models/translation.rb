class Translation < ActiveRecord::Base
  
  def self.lookup(class_name, id, field, language)
    language ||= :eng
    t = find_by_class_name_and_obj_id_and_fld_and_language(class_name, id, field, language)
    t ? t.str : nil
  end
end
