# frozen_string_literal: true

# Common methods for classes that have fields that are translatable into other languages
module Translatable
  extend ActiveSupport::Concern

  module ClassMethods
    def translates(*args)
      # Shave off the optional options hash at the end and merge with defaults.
      options = args[-1].is_a?(Hash) ? args.delete_at(-1) : {}

      # Tidy options if given.
      options[:locales] = options[:locales].map(&:to_s) if options[:locales].is_a?(Array)

      class_variable_set("@@translate_options", options)
      class_variable_set("@@translated_fields", args)

      # Setup an accessor if not present.
      translated_fields.each do |f|
        attr_accessor("#{f}_translations") unless ancestors.include?(ActiveRecord::Base)
      end

      # Setup *_translations assignment handlers for each field.
      translated_fields.each do |field|
        class_eval %{
          def #{field}_translations=(val)
            translatable_set_hash('#{field}', val)
          end
        }
      end
    end

    # special accessors that we have to use for class vars in concerns
    def translated_fields
      class_variable_defined?("@@translated_fields") ? class_variable_get("@@translated_fields") : nil
    end

    def translate_options
      class_variable_defined?("@@translate_options") ? class_variable_get("@@translate_options") : nil
    end

    def validates_translated_length_of(*attr_names)
      attr_names = attr_names.map do |attr_name|
        attr_name.is_a?(Symbol) ? "#{attr_name}_translations".to_sym : attr_name
      end
      validates_with(Translatable::TranslatableLengthValidator, _merge_attributes(attr_names))
    end
  end

  # define methods like name_en, etc.
  # possible forms:
  # name
  # name_en
  # name("en")
  # name(:en)
  # name(:en, fallbacks: true)
  # name=
  # name_en=
  #
  # the :fallbacks option defines what will happen if the desired translation is not found
  #   if false (which is the default when an explicit locale is given), nil is returned
  #   if true, then if the following locales will be tried: I18n.locale, I18n.default_locale,
  #   any locale with a non-blank translation.
  #     if all these are undefined then nil will be returned
  def method_missing(*args)
    # check if this is a translation method and get the pieces
    action, field, locale, is_setter, options = translatable_parse_method(args[0], args[1], args[2])

    # do the action if we found one
    if action
      send("translatable_#{action}", field, locale, is_setter, options, args)
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

  # Sets field_translations value internally.
  def translatable_set_hash(field, value)
    unless value.nil?
      # Remove any blank values and stringify.
      value = value.reject { |_, v| v.blank? }.stringify_keys

      # Set back to nil if empty
      value = nil if value.empty?
    end

    translatable_set(field, value)
    translatable_set_canonical(field)
  end

  # Assigns the canonical_xxx attrib if applicable
  def translatable_set_canonical(field)
    # Set canonical_name if appropriate
    return unless respond_to?("canonical_#{field}=")
    trans = translatable_get(field) || {}
    send("canonical_#{field}=", trans[I18n.default_locale.to_s] || trans.values.first)
  end

  def translatable_translate(field, locale, is_setter, options, args)
    # if we're setting the value
    if is_setter
      cur_hash = translatable_get(field) || {}

      # set the value in the appropriate translation hash
      # we use the merge method because otherwise the _changed? method doesn't work right
      translatable_set_hash(field, cur_hash.merge(locale => args[1]))

    # otherwise just return what we have
    else
      translations = translatable_get(field)
      return nil if translations.nil?

      to_try = [locale.to_s]
      to_try += [I18n.locale.to_s, I18n.default_locale.to_s] + translations.keys if options[:fallbacks]

      # If allowed locales are given, restrict attempted locales to those.
      allowed = Setting.for_mission(mission_id)&.preferred_locales
      to_try &= allowed.map(&:to_s) if allowed.present?

      to_try.each do |l|
        if (found = translations[l])
          return found
        end
      end

      nil
    end
  end

  # checks if all the translations are blank for the given field
  def translatable_all_blank?(field, _locale, _is_setter, _options, _args)
    translatable_get(field).nil? || !translatable_get(field).detect { |_l, t| t.present? }
  end

  def translatable_parse_method(symbol, arg1 = nil, arg2 = nil)
    return nil if self.class.translated_fields.nil?

    fields = self.class.translated_fields.join("|")
    if symbol.to_s =~ /\A(#{fields})(_([a-z]{2}))?(_before_type_cast)?(=?)\z/

      # get bits
      action = :translate
      field = Regexp.last_match(1)
      locale = Regexp.last_match(3)
      is_setter = Regexp.last_match(5) == "="
      options = arg1.is_a?(Hash) ? arg1 : (arg2.is_a?(Hash) ? arg2 : {})

      # if locale is nil, we need to figure out what it is
      if locale.nil?
        # if it's a setter method (e.g. name = "foo")
        # then we need to use the current system locale, b/c the locale is not specified
        if is_setter
          locale = I18n.locale

        # otherwise (it's a getter), we can assume that the locale is in the 1st argument
        # (e.g. name(:en), name(:en, fallbacks: true))
        # (unless that first arg was a hash (e.g. name(fallbacks: true)))
        else
          locale = arg1 unless arg1.is_a?(Hash)
        end
      end

      # if locale is still not set (can only be true for getters),
      # default to current locale, but turn on fallbacks
      if locale.blank?
        locale = I18n.locale
        options[:fallbacks] = true
      else
        # otherwise, default fallbacks to false unless expressly set to true by user
        options[:fallbacks] = false unless options[:fallbacks] == true
      end

      # if we get this far, return the bits (locale should always be a string)
      [action, field, locale.to_s, is_setter, options]

    elsif symbol.to_s =~ /\A(#{fields})_all_blank\?\z/
      action = :all_blank?
      field = Regexp.last_match(1)

      [action, field]
    end
  end

  def translatable_get(field)
    if is_a?(ActiveRecord::Base)
      self[:"#{field}_translations"]
    else
      instance_variable_get("@#{field}_translations")
    end
  end

  def translatable_set(field, value)
    if is_a?(ActiveRecord::Base)
      self[:"#{field}_translations"] = value
    else
      instance_variable_set("@#{field}_translations", value)
    end
  end

  def available_locales(options = {})
    # get union of all locales of all translated fields, and convert to symbol
    locales = self.class.translated_fields.inject([]) do |union, field|
      trans = translatable_get(field)
      union |= trans.keys unless trans.nil?
      union
    end.map(&:to_sym)

    # honor :except_current option
    locales -= [I18n.locale] if options[:except_current]

    locales
  end
end
module Translatable
  class TranslatableLengthValidator < ActiveModel::Validations::LengthValidator
    # The tokenizer determines how to split up an attribute value
    # before it is counted by the length validator
    # by default, it will split a string based on characters,
    # but you can pass in a proc to use a different tokenizer
    # this only works for strings, however.
    # For these serialized fields, the value the validator has
    # access to is a hash so this overridden tokenizer
    # checks for a hash and converts it to its json representation to
    # count the number of characters before storing it
    def tokenize(value)
      if value.is_a?(String)
        if options[:tokenizer]
          options[:tokenizer].call(value)
        elsif !value.encoding_aware?
          value.mb_chars
        end
      elsif value.is_a?(Hash)
        value.to_json
      end
    end
  end
end
