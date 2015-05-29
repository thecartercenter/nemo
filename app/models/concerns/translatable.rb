# common methods for classes that have fields that are translatable into other languages
module Translatable
  extend ActiveSupport::Concern

  included do

  end

  module ClassMethods

    def translates(*args)
      # shave off the optional options hash at the end
      class_variable_set('@@translate_options', args[-1].is_a?(Hash) ? args.delete_at(-1) : {})

      # save the list of translated fields
      class_variable_set('@@translated_fields', args)

      # set up the _tranlsations fields to serialize
      translated_fields.each do |f|
        ancestors.include?(ActiveRecord::Base) ? (serialize "#{f}_translations", JSON) : (attr_accessor "#{f}_translations")
      end

      # Setup *_translations assignment handlers for each field.
      translated_fields.each do |field|
        class_eval %Q{
          def #{field}_translations=(val)
            translatable_external_set_hash('#{field}', val)
          end
        }
      end
    end

    # special accessors that we have to use for class vars in concerns
    def translated_fields
      class_variable_defined?('@@translated_fields') ? class_variable_get('@@translated_fields') : nil
    end

    def translate_options
      class_variable_defined?('@@translate_options') ? class_variable_get('@@translate_options') : nil
    end
  end

  # define methods like name_en, etc.
  # possible forms:
  # name
  # name_en
  # name("en")
  # name(:en)
  # name(:en, :strict => false)
  # name=
  # name_en=
  #
  # the :strict option defines what will happen if the desired translation is not found
  #   if true (which is the default when an explicit locale is given), nil is returned
  #   if false, then if the following locales will be tried: I18n.locale, I18n.default_locale, any locale with a non-blank translation.
  #     if all these are undefined then nil will be returned
  def method_missing(*args)
    # check if this is a translation method and get the pieces
    action, field, locale, is_setter, options = translatable_parse_method(args[0], args[1], args[2])

    # do the action if we found one
    if action
      self.send("translatable_#{action}", field, locale, is_setter, options, args)
    else
      super
    end
  end

  def respond_to?(symbol, *)
    !self.class.translated_fields.nil? && translatable_parse_method(symbol) || super
  end

  def respond_to_missing?(symbol, include_private)
    !self.class.translated_fields.nil? && translatable_parse_method(symbol) || super
  end

  # Called when someone directly assigns field_translations.
  def translatable_external_set_hash(field, value)
    translatable_internal_set_hash(field, value)
    translatable_set_canonical(field)
  end

  # Sets field_translations value internally.
  def translatable_internal_set_hash(field, value)
    # Use write_attribute if available.
    value = value.try(:stringify_keys)
    respond_to?(:write_attribute, true) ? write_attribute(:"#{field}_translations", value) : instance_variable_set("@#{field}_translations", value)
  end

  # Assigns the canonical_xxx attrib if applicable
  def translatable_set_canonical(field)
    # Set canonical_name if appropriate
    if respond_to?("canonical_#{field}=")
      trans = send("#{field}_translations") || {}
      send("canonical_#{field}=", trans[I18n.default_locale.to_s] || trans.values.first)
    end
  end

  def translatable_translate(field, locale, is_setter, options, args)

    # if we're setting the value
    if is_setter
      # init the empty hash if it's nil
      translatable_internal_set_hash(field, {}) if send("#{field}_translations").nil?

      # set the value in the appropriate translation hash
      # we use the merge method because otherwise the _changed? method doesn't work right
      translatable_internal_set_hash(field, send("#{field}_translations").merge(locale => args[1]))

      # Remove any blank values.
      translatable_internal_set_hash(field, send("#{field}_translations").reject{ |k,v| v.blank? })

      # Set back to nil if empty
      translatable_internal_set_hash(field, nil) if send("#{field}_translations").blank?

      translatable_set_canonical(field)

    # otherwise just return what we have
    else
      if send("#{field}_translations").nil?
        str = nil
      else
        # try the specified locale
        str = send("#{field}_translations")[locale]

        # if the translation is blank and strict mode is off
        if str.blank? && !options[:strict]
          # try the current locale
          str = send("#{field}_translations")[I18n.locale.to_s]

          if str.blank?
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
      end

      # return whatever we have at this point, could be nil
      return str
    end
  end

  # checks if all the translations are blank for the given field
  def translatable_all_blank?(field, locale, is_setter, options, args)
    send("#{field}_translations").nil? || !send("#{field}_translations").detect{|l,t| !t.blank?}
  end

  def translatable_parse_method(symbol, arg1 = nil, arg2 = nil)
    return nil if self.class.translated_fields.nil?

    fields = self.class.translated_fields.join("|")
    if symbol.to_s.match(/\A(#{fields})(_([a-z]{2}))?(_before_type_cast)?(=?)\z/)

      # get bits
      action = :translate
      field = $1
      locale = $3
      is_setter = $5 == "="
      options = arg1.is_a?(Hash) ? arg1 : (arg2.is_a?(Hash) ? arg2 : {})

      # if locale is nil, we need to figure out what it is
      if locale.nil?
        # if it's a setter method (e.g. name = "foo")
        # then we need to use the current system locale, b/c the locale is not specified
        if is_setter
          locale = I18n.locale

        # otherwise (it's a getter), we can assume that the locale is in the 1st argument (e.g. name(:en), name(:en, :strict => false))
        # (unless that first arg was a hash (e.g. name(:strict => false)))
        else
          locale = arg1 unless arg1.is_a?(Hash)
        end
      end

      # if locale is still not set (can only be true for getters), default to current locale, but turn off strict mode
      if locale.blank?
        locale = I18n.locale
        options[:strict] = false
      else
        # otherwise, default strict mode to true unless expressly set to false by user
        options[:strict] = true unless options[:strict] == false
      end

      # if we get this far, return the bits (locale should always be a string)
      [action, field, locale.to_s, is_setter, options]

    elsif symbol.to_s.match(/\A(#{fields})_all_blank\?\z/)
      action = :all_blank?
      field = $1

      [action, field]
    else
      nil
    end
  end

  def available_locales(options = {})
    # get union of all locales of all translated fields, and convert to symbol
    locales = self.class.translated_fields.inject([]) do |union, field|
      trans = send("#{field}_translations")
      union |= trans.keys unless trans.nil?
      union
    end.map{|l| l.to_sym}

    # honor :except_current option
    locales -= [I18n.locale] if options[:except_current]

    locales
  end
end