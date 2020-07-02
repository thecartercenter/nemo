# frozen_string_literal: true

module Forms
  module IntegrityWarnings
    # Enumerates integrity warnings for Forms
    class Warner
      MAX_FORMS = 3
      MAX_QUESTIONS = 3

      attr_accessor :object

      def initialize(object)
        self.object = object
      end

      def warnings(type)
        # Expects the subclass method with name `type` to return an array of
        # 1) symbols or 2) 2-element arrays of form [symbol, hash].
        # The first symbol is the boolean method to call on the object
        # to check if the warning should be shown.
        # The hash (if given) is a hash of options that currently only includes i18n_params.
        # i18n_params can be a Proc.
        #
        # Returns an array of hashes of form {reason:, i18n_params:}
        send(type).map do |params|
          reason, options = params.is_a?(Array) ? params : [params, {}]

          # No need to proceed any further if the object returns false for the reason method.
          next unless object.send("#{reason}?")

          # If we get this far we need to actually generate the i18n params, if given.
          i18n_params = if options[:i18n_params].is_a?(Proc)
                          options[:i18n_params].call
                        else
                          options[:i18n_params]
                        end
          {reason: reason, i18n_params: i18n_params}
        end.compact
      end
    end
  end
end
