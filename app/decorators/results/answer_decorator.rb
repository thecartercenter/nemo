# frozen_string_literal: true

module Results
  class AnswerDecorator < ResponseNodeDecorator
    def classes
      ["answer", "form-field", "qtype-#{qtype_name.dasherize}", mode_class, error_class].compact.join(" ")
    end

    def hint
      question_hint = questioning.hint&.chomp(".")&.concat(".")
      drop_hint = h.t("response.drop_hint.#{qtype.name}", default: "").presence
      [question_hint, drop_hint].join(" ")
    end

    def shortened
      case qtype_name
      when "select_one"
        option_name
      when "select_multiple"
        choices.map(&:option_name).join(", ")
      when "datetime", "date"
        casted_value.present? ? h.l(casted_value) : nil
      when "time"
        time_value.present? ? h.l(time_value, format: :time_only) : nil
      when "decimal"
        value.present? ? format("%.2f", value.to_f) : nil
      when "text", "long_text", "barcode"
        h.truncate(h.sanitize(value), length: 32, escape: false)
      when "integer", "counter", "location"
        value
      end
    end
  end
end
