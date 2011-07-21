module Translatable
  def translation_for(field, lang)
    lang ||= Language.english
    trans = translation_hash["#{field.to_s}__#{lang.id}"]
    trans ? trans.str : nil
  end
  def translation_hash
    @translation_hash ||= Hash[*translations.collect{|t| ["#{t.fld}__#{t.language_id}", t]}.flatten]
  end
end