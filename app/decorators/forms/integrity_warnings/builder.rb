# frozen_string_literal: true

module Forms
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
        warnings = warner.warnings(type)
        return if warnings.empty?
        h.content_tag(:div, class: "alert alert-warning integrity-warning media") do
          h.icon_tag("warning") << h.content_tag(:div, class: "media-body") do
            h.content_tag(:strong, t("integrity_warnings.titles.#{type}")) << list_or_single(warnings)
          end
        end
      end

      def warner
        class_name = object.class.name.sub(/Decorator\z/, "")
        "Forms::IntegrityWarnings::#{class_name}Warner".constantize.new(object)
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

      def text(warning)
        key = "integrity_warnings.reasons.#{object.model_name.i18n_key}.#{warning[:reason]}"
        t(key, warning[:i18n_params] || {})
      end
    end
  end
end
