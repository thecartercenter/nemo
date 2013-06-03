# common methods for classes that have fields that are translatable into other languages
module Translatable
  extend ActiveSupport::Concern
  
  included do
  end
  
  module ClassMethods
    def translates(*fields)
      # save the list of translated fields
      @@translated_fields = fields
      
      # set up the _tranlsations fields to serialize
      fields.each do |f|
        serialize "#{f}_translations", JSON
      end
    end
    
    # accessor
    def translated_fields
      @@translated_fields
    end
  end
  
  # define methods like name_en, etc.
  def method_missing(*args)
    # check if this is a translation method and get the pieces
    field, locale, is_setter = is_translation_method?(args[0])
    if field
      # if we're setting the value
      if is_setter
        # init the empty hash if it's nil
        send("#{field}_translations=", {}) if send("#{field}_translations").nil?
      
        # set the value in the appropriate translation hash
        # we use the merge method because otherwise the _changed? method doesn't work right
        send("#{field}_translations=", send("#{field}_translations").merge(locale => args[1]))
        
        # if the locale is the default locale, also put the value in the vanilla attribute
        send("#{field}=", args[1]) if locale.to_sym == I18n.default_locale
        
      # otherwise just return what we have
      else
        send("#{field}_translations").nil? ? nil : send("#{field}_translations")[locale]
      end
    else
      super
    end
  end
  
  def respond_to?(symbol, *)
    is_translation_method?(symbol) || super
  end
  
  def respond_to_missing?(symbol, include_private)
    is_translation_method?(symbol) || super
  end
  
  def is_translation_method?(symbol)
    # check the general format
    return false unless symbol.to_s.match(/^(\w+)_([a-z]{2})(_before_type_cast)?(=?)$/)
    
    # get bits
    field = $1
    locale = $2
    is_setter = $4 == "="
    
    # make sure the field matches one of the translated fields
    return false unless self.class.translated_fields.include?(field.to_sym)
    
    # if we get this far, return the bits
    [field, locale, is_setter]
  end  
end