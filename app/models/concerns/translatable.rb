# frozen_string_literal: true

# Common methods for classes that have fields that are translatable into other languages
module Translatable
  extend ActiveSupport::Concern

  module ClassMethods
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
    def translates(*fields)
      fields.each do |field|
        define_method(field.to_s) do |locale = nil, **kwargs|
          fallbacks = kwargs.fetch(:fallbacks, true)
          get_translation(field, locale, fallbacks: fallbacks)
        end

        define_method("#{field}=") { |locale = nil, value| set_translation(field, locale, value) }

        attr_accessor("#{field}_translations") unless ancestors.include?(ActiveRecord::Base)

        # we must override these setters because of the canonical_name setup
        define_method("#{field}_translations=") { |value| set_translation_hash(field, value) }

        I18n.available_locales.each do |locale|
          define_method("#{field}_#{locale}") { get_translation(field, locale, fallbacks: false) }
          define_method("#{field}_#{locale}=") { |value| set_translation(field, locale, value) }
        end
      end
    end

    def validates_translated_length_of(*attr_names)
      attr_names = attr_names.map do |attr_name|
        attr_name.is_a?(Symbol) ? "#{attr_name}_translations".to_sym : attr_name
      end
      validates_with(Translatable::TranslatableLengthValidator, _merge_attributes(attr_names))
    end
  end

  def get_translation_hash(field)
    hash = if is_a?(ActiveRecord::Base)
      send("#{field}_translations")
    else
      instance_variable_get("@#{field}_translations")
    end
    return nil if hash.empty?
    hash
  end

  def set_translation_hash(field, hash)
    hash = hash.compact

    canonical_translation = hash[I18n.default_locale.to_s] || hash.values.first
    set_canonical_translation(field, canonical_translation) if canonical_translation.present?

    if is_a?(ActiveRecord::Base)
      # this weird construct is necessary because we override the `field_translations` setters
      self[:"#{field}_translations"] = hash
    else
      instance_variable_set("@#{field}_translations", hash)
    end
  end

  def get_translation(field, locale, fallbacks:) # rubocop:disable Metrics/PerceivedComplexity
    # locale specified
    if locale
      translation = get_translation_hash(field)&.dig(locale.to_s)
      return translation if translation.present?
    elsif fallbacks
      locales_to_try = []
      locales_to_try << I18n.locale
      locales_to_try << Setting.for_mission(mission_id).preferred_locales
      locales_to_try << I18n.default_locale

      locales_to_try.map(&:to_s).uniq.each do |l|
        translation = get_translation_hash(field)&.dig(l.to_s)
        return translation if translation.present?
      end

      get_translation_hash(field).each do |_locale, t|
        return t if t.present?
      end
    end

    nil
  end

  def set_translation(field, locale, value)
    locale ||= I18n.locale

    current_hash = get_translation_hash(field) || {}
    current_hash[locale.to_s] = value
    set_translation_hash(field, current_hash)
  end

  def set_canonical_translation(field, value)
    return unless respond_to?("canonical_#{field}=")
    send("canonical_#{field}=", value)
  end

  def method_missing(*args)
    Rails::Debug.log("METHOD MISSING")
    Rails::Debug.log("\t#{args.awesome_inspect}")
    Rails::Debug.log("END METHOD MISSING")
    super
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
