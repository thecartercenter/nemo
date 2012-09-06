module Translatable
  def translation_obj_for(field, lang)
    lang ||= :eng
    trans = translation_hash["#{field.to_s}__#{lang}"]
  end
  def translation_for(field, lang)
    trans = translation_obj_for(field, lang)
    trans ? trans.str : nil
  end
  def set_translation_for(field, lang, str)
    trans = translation_obj_for(field, lang)
    unless trans
      trans = translations.build(:fld => field, :class_name => self.class.name, :language => lang)
      translation_hash(:rebuild => true)
    end
    trans.str = str
  end
  def translation_hash(options = {})
    if !@translation_hash || options[:rebuild]
      @translation_hash = Hash[*translations.collect{|t| ["#{t.fld}__#{t.language}", t]}.flatten]
    end
    @translation_hash
  end
end