# frozen_string_literal: true

module I18n
  module Backend
    # Overriding the pluralization method so if the proper plural form is missing we will try
    # to fallback to the default gettext plural form (which is the `germanic` one).
    # From: https://github.com/svenfuchs/i18n/issues/123
    # See spec/helpers/arabic_missing_plural_spec.rb for spec that fails without this.
    module Pluralization
      def pluralize(locale, entry, count)
        return entry unless entry.is_a?(Hash) && count

        pluralizer = pluralizer(locale)
        if pluralizer.respond_to?(:call)
          return entry[:zero] if count.zero? && entry.key?(:zero)

          plural_key = pluralizer.call(count)
          return entry[plural_key] if entry.key?(plural_key)

          # fallback to the default gettext plural forms if real entry is missing (for example :few)
          default_gettext_key = count == 1 ? :one : :other
          return entry[default_gettext_key] if entry.key?(default_gettext_key)

          # If nothing is found throw the classic exception
          raise InvalidPluralizationData.new(entry, count, plural_key)
        else
          super
        end
      end
    end
  end
end
