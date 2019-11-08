# frozen_string_literal: true

module IntegrityWarnings
  # Builds HTML for integrity warnings
  class Builder < ApplicationDecorator
    attr_accessor :object

    def initialize(object)
      self.object = object
    end

    def to_s
      [warnings_of_type(:careful_with_changes), warnings_of_type(:features_disabled)].compact.reduce(:<<)
    end

    private

    def warnings_of_type(type)
      warnings = warner.send(type)
      return if warnings.empty?
      h.content_tag(:div, class: "alert alert-warning media") do
        h.icon_tag("warning") << h.content_tag(:div, class: "media-body") do
          h.content_tag(:h3, t("integrity_warnings.#{type}.main")) << list_or_single(warnings)
        end
      end
    end

    def warner
      "IntegrityWarnings::#{object.class.name}Warner".constantize.new(object)
    end

    def list_or_single(warnings)
      if warnings.one?
        h.content_tag(:p, text(warnings[0]))
      else
        h.content_tag(:ul) do
          warnings.map { |warning| h.content_tag(:li, text(warning)) }.reduce(:<<)
        end
      end
    end

    # `warning` should consist of either a symbol or a 2-element array of form [key, params],
    # where key is the i18n key and params is an optional hash of i18n interpolation params.
    def text(warning)
      warning = Array.wrap(warning)
      t("integrity_warnings.reasons.#{object.model_name.i18n_key}.#{warning[0]}", warning[1] || {})
    end
  end
end
