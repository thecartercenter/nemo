# frozen_string_literal: true

module Forms
  module IntegrityWarnings
    # Enumerates integrity warnings for Questions
    class QuestionWarner < Warner
      protected

      # See Warner#warnings for more info on the expected return value here.
      def careful_with_changes
        [
          [:in_use, {i18n_params: -> { {form_list: form_list} }}],
          :published,
          :standard_copy
        ]
      end

      def features_disabled
        # We include standard_copy here because editing the question code is not allowed
        # for standard copies.
        %i[published data standard_copy]
      end

      def form_list
        form_count = object.forms.size
        more_suffix =
          if form_count > MAX_FORMS
            str = I18n.t("integrity_warnings.more_suffix", count: form_count - MAX_FORMS)
            "(+#{str})"
          end
        [object.forms.by_name[0...MAX_FORMS].map(&:name).join(", "), more_suffix].compact.join(" ")
      end
    end
  end
end
