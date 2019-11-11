# frozen_string_literal: true

module IntegrityWarnings
  # Enumerates integrity warnings for Forms
  class Warner
    attr_accessor :object

    def initialize(object)
      self.object = object
    end

    def warnings(type)
      # Expects the subclass method with name `type` to return an array of
      # symbols or arrays of form [symbol, symbol].
      # The first symbol is the boolean method to call on the object to check if the warning should be shown.
      # The second symbol (in the array case) is a method to be called locally to provide extra
      # info for I18n.
      send(type).map do |params|
        if params.is_a?(Array) && object.send("#{params[0]}?")
          [params[0], params[1] => send(params[1])]
        elsif object.send("#{params}?")
          params
        end
      end.compact
    end

    protected

    def form_list
      form_count = object.forms.size
      more_suffix = form_count > 3 ? I18n.t("integrity_warnings.more_suffix", count: form_count - 3) : nil
      [object.forms.map(&:name).join(", "), more_suffix].compact.join(" ")
    end
  end
end
