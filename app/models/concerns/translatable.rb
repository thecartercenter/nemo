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
    field, locale, is_setter = parse_method(args[0], args[1])
    
    if field
      # if locale is not set, default to current locale, but remember that we did this
      if locale.blank?
        locale = I18n.locale.to_s
        implicit_locale = true
      else
        implicit_locale = false
      end

      # if we're setting the value
      if is_setter
        # init the empty hash if it's nil
        send("#{field}_translations=", {}) if send("#{field}_translations").nil?
        
        # set the value in the appropriate translation hash
        # we use the merge method because otherwise the _changed? method doesn't work right
        send("#{field}_translations=", send("#{field}_translations").merge(locale => args[1]))
        
        # if the locale is the default locale, also cache the value in the _ attribute
        send("_#{field}=", args[1]) if locale.to_sym == I18n.default_locale
        
      # otherwise just return what we have
      else
        if send("#{field}_translations").nil?
          str = nil
        else
          # try the specified locale
          str = send("#{field}_translations")[locale]
        
          # if the translation is blank and the locale was implicit
          if str.blank? && implicit_locale
            # try the default locale
            str = send("#{field}_translations")[I18n.default_locale.to_s]
          
            # if str is still blank, search the translations for /any/ non-blank string
            if str.blank?
              if (non_blank_pair = send("#{field}_translations").find{|locale, value| !value.blank?})
                str = non_blank_pair[1]
              end
            end
          end
        end
        
        # return whatever we have at this point, could be nil
        return str
      end
    else
      super
    end
  end
  
  def respond_to?(symbol, *)
    parse_method(symbol) || super
  end
  
  def respond_to_missing?(symbol, include_private)
    parse_method(symbol) || super
  end
  
  def parse_method(symbol, arg1 = nil)
    fields = self.class.translated_fields.join("|")
    if symbol.to_s.match(/^(#{fields})(_([a-z]{2}))?(_before_type_cast)?(=?)$/) 
    
      # get bits
      field = $1
      locale = $3 || arg1.to_s
      is_setter = $5 == "="
      
      # if we get this far, return the bits
      [field, locale, is_setter]
    else
      nil
    end
  end  
end