# frozen_string_literal: true

module Forms
  module IntegrityWarnings
    # Enumerates integrity warnings for Forms
    class Warner
      MAX_FORMS = 3

      attr_accessor :object

      def initialize(object)
        self.object = object
      end

      def warnings(type)
        # Expects the subclass method with name `type` to return an array of
        # symbols or 1-element hashes of form [symbol => symbol].
        # The first symbol is the boolean method to call on the object to check if the warning should be shown.
        # The second symbol (in the array case) is a method to be called locally to provide extra
        # info for I18n.
        send(type).map do |params|
          if params.is_a?(Hash)
            [params.first[0], params.first[1] => send(params.first[1])] if object.send("#{params.first[0]}?")
          elsif object.send("#{params}?")
            params
          end
        end.compact
      end

      protected

      def form_list
        form_count = object.forms.size
        more_suffix =
          if form_count > MAX_FORMS
            str = I18n.t("integrity_warnings.more_suffix", count: form_count - 3)
            "(+#{str})"
          end
        [object.forms.by_name[0...MAX_FORMS].map(&:name).join(", "), more_suffix].compact.join(" ")
      end
    end
  end
end
